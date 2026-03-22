# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::Anthropic do
  let(:direct_access_url) { 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access' }

  let(:token_response_body) do
    {
      token: 'gateway-token-abc',
      headers: {
        'X-Gitlab-Instance-Id' => 'instance-abc',
        'X-Gitlab-Global-User-Id' => 'user-456',
        'x-api-key' => 'should-be-filtered'
      }
    }.to_json
  end

  before do
    RubyLLM.configure do |config|
      config.gitlab_api_key = 'glpat-test-token'
    end

    stub_request(:post, direct_access_url)
      .to_return(
        status: 200,
        body: token_response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  subject(:provider) { described_class.new(RubyLLM.config) }

  describe 'inheritance' do
    it 'inherits from RubyLLM::Providers::Anthropic' do
      expect(described_class.superclass).to eq(RubyLLM::Providers::Anthropic)
    end

    it 'includes GitLab::Chat module' do
      expect(described_class.ancestors).to include(RubyLLM::Providers::GitLab::Chat)
    end
  end

  describe '#api_base' do
    it 'returns anthropic proxy URL' do
      expect(provider.api_base).to eq('https://cloud.gitlab.com/ai/v1/proxy/anthropic')
    end
  end

  describe '#headers' do
    it 'includes Authorization with Bearer token' do
      expect(provider.headers['Authorization']).to eq('Bearer gateway-token-abc')
    end

    it 'includes anthropic-version header' do
      expect(provider.headers['anthropic-version']).to eq('2023-06-01')
    end

    it 'includes gateway headers' do
      headers = provider.headers
      expect(headers['X-Gitlab-Instance-Id']).to eq('instance-abc')
      expect(headers['X-Gitlab-Global-User-Id']).to eq('user-456')
    end

    it 'does NOT include x-api-key' do
      expect(provider.headers).not_to have_key('x-api-key')
    end
  end

  describe '.slug' do
    it "returns 'gitlab_anthropic'" do
      expect(described_class.slug).to eq('gitlab_anthropic')
    end
  end

  describe '.configuration_options' do
    it 'returns gitlab config keys' do
      expect(described_class.configuration_options).to eq(%i[gitlab_api_key gitlab_instance_url gitlab_gateway_url])
    end
  end

  describe '.configuration_requirements' do
    it 'returns [:gitlab_api_key]' do
      expect(described_class.configuration_requirements).to eq(%i[gitlab_api_key])
    end
  end

  describe '.assume_models_exist?' do
    it 'returns true' do
      expect(described_class.assume_models_exist?).to be(true)
    end
  end
end
