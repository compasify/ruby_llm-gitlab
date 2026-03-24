# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::TokenManager do
  let(:config) { RubyLLM.config }
  let(:manager) { described_class.new(config) }

  let(:token_response) do
    {
      'token' => 'gw-token-abc123',
      'headers' => {
        'x-gitlab-host-name' => 'gitlab.com',
        'x-gitlab-instance-id' => 'inst-123',
        'x-api-key' => 'secret-key-should-be-filtered'
      }
    }
  end

  before do
    stub_request(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access')
      .with(
        headers: { 'Authorization' => 'Bearer glpat-test-token' },
        body: { feature_flags: { DuoAgentPlatformNext: true } }
      )
      .to_return(
        status: 200,
        body: JSON.generate(token_response),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#token' do
    it 'fetches and returns the gateway token' do
      expect(manager.token).to eq('gw-token-abc123')
    end

    it 'caches the token on subsequent calls' do
      manager.token
      manager.token
      expect(WebMock).to have_requested(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access').once
    end
  end

  describe '#gateway_headers' do
    it 'returns headers from the response' do
      headers = manager.gateway_headers
      expect(headers['x-gitlab-host-name']).to eq('gitlab.com')
      expect(headers['x-gitlab-instance-id']).to eq('inst-123')
    end

    it 'filters out x-api-key from headers' do
      headers = manager.gateway_headers
      expect(headers).not_to have_key('x-api-key')
    end
  end

  describe '#invalidate!' do
    it 'clears the cache so next call re-fetches' do
      manager.token
      manager.invalidate!
      manager.token
      expect(WebMock).to have_requested(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access').twice
    end
  end

  describe '#anthropic_base_url' do
    it 'returns the Anthropic proxy URL' do
      expect(manager.anthropic_base_url).to eq('https://cloud.gitlab.com/ai/v1/proxy/anthropic')
    end
  end

  describe '#openai_base_url' do
    it 'returns the OpenAI proxy URL' do
      expect(manager.openai_base_url).to eq('https://cloud.gitlab.com/ai/v1/proxy/openai/v1')
    end
  end

  describe 'thread safety' do
    it 'only fetches the token once under concurrent access' do
      threads = 5.times.map do
        Thread.new { manager.token }
      end
      threads.each(&:join)
      expect(WebMock).to have_requested(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access').once
    end
  end

  describe 'error handling' do
    before do
      WebMock.reset!
      stub_request(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access')
        .to_return(status: 401, body: 'Unauthorized')
    end

    it 'raises ConfigurationError on fetch failure' do
      expect { manager.token }.to raise_error(RubyLLM::ConfigurationError, /Failed to obtain GitLab direct access token/)
    end
  end

  describe 'custom instance URL' do
    let(:config) do
      cfg = RubyLLM.config
      cfg.gitlab_instance_url = 'https://gitlab.example.com'
      cfg
    end

    before do
      WebMock.reset!
      stub_request(:post, 'https://gitlab.example.com/api/v4/ai/third_party_agents/direct_access')
        .to_return(
          status: 200,
          body: JSON.generate(token_response),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'uses the custom instance URL' do
      manager.token
      expect(WebMock).to have_requested(:post, 'https://gitlab.example.com/api/v4/ai/third_party_agents/direct_access')
    end
  end
end
