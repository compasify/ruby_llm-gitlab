# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::TokenManager do
  let(:config) do
    double('Config',
           gitlab_api_key: 'glpat-test-token',
           gitlab_instance_url: nil,
           gitlab_gateway_url: nil)
  end

  let(:direct_access_url) { 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access' }

  let(:token_response_body) do
    {
      token: 'test-token-123',
      headers: {
        'X-Gitlab-Instance-Id' => 'instance-abc',
        'X-Gitlab-Global-User-Id' => 'user-456',
        'x-api-key' => 'should-be-filtered'
      }
    }.to_json
  end

  subject(:manager) { described_class.new(config) }

  before do
    stub_request(:post, direct_access_url)
      .to_return(
        status: 200,
        body: token_response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#token' do
    it 'fetches from direct_access endpoint when no cached token' do
      expect(manager.token).to eq('test-token-123')
      expect(WebMock).to have_requested(:post, direct_access_url).once
    end

    it 'sends PAT as Bearer authorization' do
      manager.token
      expect(WebMock).to have_requested(:post, direct_access_url)
        .with(headers: { 'Authorization' => 'Bearer glpat-test-token' })
    end

    it 'sends feature_flags in request body' do
      manager.token
      expect(WebMock).to have_requested(:post, direct_access_url)
        .with(body: { feature_flags: { DuoAgentPlatformNext: true } })
    end

    it 'returns cached token when still valid' do
      manager.token
      manager.token
      expect(WebMock).to have_requested(:post, direct_access_url).once
    end

    it 'refreshes when token is expired' do
      manager.token
      manager.instance_variable_set(:@token_expires_at, Time.now - 1)

      manager.token
      expect(WebMock).to have_requested(:post, direct_access_url).twice
    end
  end

  describe '#gateway_headers' do
    it 'filters out x-api-key from response headers' do
      headers = manager.gateway_headers
      expect(headers).not_to have_key('x-api-key')
    end

    it 'preserves other gateway headers' do
      headers = manager.gateway_headers
      expect(headers['X-Gitlab-Instance-Id']).to eq('instance-abc')
      expect(headers['X-Gitlab-Global-User-Id']).to eq('user-456')
    end

    it 'returns cached headers on subsequent calls' do
      manager.gateway_headers
      manager.gateway_headers
      expect(WebMock).to have_requested(:post, direct_access_url).once
    end
  end

  describe '#invalidate!' do
    it 'clears cached token and forces re-fetch' do
      manager.token
      manager.invalidate!
      manager.token
      expect(WebMock).to have_requested(:post, direct_access_url).twice
    end

    it 'clears cached headers' do
      manager.gateway_headers
      manager.invalidate!
      manager.gateway_headers
      expect(WebMock).to have_requested(:post, direct_access_url).twice
    end
  end

  describe '#anthropic_base_url' do
    it 'returns correct proxy URL with default gateway' do
      expect(manager.anthropic_base_url).to eq('https://cloud.gitlab.com/ai/v1/proxy/anthropic')
    end

    context 'with custom gateway URL' do
      let(:config) do
        double('Config',
               gitlab_api_key: 'glpat-test-token',
               gitlab_instance_url: nil,
               gitlab_gateway_url: 'https://ai-gateway.example.com')
      end

      it 'returns proxy URL with custom gateway' do
        expect(manager.anthropic_base_url).to eq('https://ai-gateway.example.com/ai/v1/proxy/anthropic')
      end
    end
  end

  describe '#openai_base_url' do
    it 'returns correct proxy URL with default gateway' do
      expect(manager.openai_base_url).to eq('https://cloud.gitlab.com/ai/v1/proxy/openai/v1')
    end

    context 'with custom gateway URL' do
      let(:config) do
        double('Config',
               gitlab_api_key: 'glpat-test-token',
               gitlab_instance_url: nil,
               gitlab_gateway_url: 'https://ai-gateway.example.com')
      end

      it 'returns proxy URL with custom gateway' do
        expect(manager.openai_base_url).to eq('https://ai-gateway.example.com/ai/v1/proxy/openai/v1')
      end
    end
  end

  context 'with custom instance URL' do
    let(:config) do
      double('Config',
             gitlab_api_key: 'glpat-test-token',
             gitlab_instance_url: 'https://gitlab.example.com',
             gitlab_gateway_url: nil)
    end

    let(:custom_direct_access_url) { 'https://gitlab.example.com/api/v4/ai/third_party_agents/direct_access' }

    before do
      stub_request(:post, custom_direct_access_url)
        .to_return(
          status: 200,
          body: token_response_body,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fetches token from custom instance' do
      manager.token
      expect(WebMock).to have_requested(:post, custom_direct_access_url).once
    end
  end

  describe 'error handling' do
    before do
      stub_request(:post, direct_access_url)
        .to_raise(Faraday::ConnectionFailed.new('connection refused'))
    end

    it 'raises ConfigurationError on Faraday error' do
      expect { manager.token }.to raise_error(
        RubyLLM::ConfigurationError,
        /Failed to obtain GitLab AI Gateway token.*connection refused/
      )
    end
  end

  describe 'thread safety' do
    it 'does not double-fetch under concurrent access' do
      WebMock.reset!
      stub_request(:post, direct_access_url)
        .to_return(
          status: 200,
          body: token_response_body,
          headers: { 'Content-Type' => 'application/json' }
        )

      threads = 5.times.map do
        Thread.new { manager.token }
      end
      threads.each(&:join)

      expect(WebMock).to have_requested(:post, direct_access_url).once
    end
  end

  describe 'constants' do
    it 'caches tokens for 25 minutes' do
      expect(described_class::TOKEN_CACHE_TTL).to eq(25 * 60)
    end

    it 'uses correct direct_access path' do
      expect(described_class::DIRECT_ACCESS_PATH).to eq('/api/v4/ai/third_party_agents/direct_access')
    end

    it 'defaults to cloud.gitlab.com gateway' do
      expect(described_class::DEFAULT_GATEWAY_URL).to eq('https://cloud.gitlab.com')
    end
  end
end
