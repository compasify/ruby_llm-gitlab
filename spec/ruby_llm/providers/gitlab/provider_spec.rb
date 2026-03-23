# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab do
  let(:config) { RubyLLM.config }
  let(:provider) { described_class.new(config) }

  let(:token_response) do
    {
      'token' => 'gw-token-abc123',
      'headers' => {
        'x-gitlab-host-name' => 'gitlab.com',
        'x-gitlab-instance-id' => 'inst-123'
      }
    }
  end

  before do
    stub_request(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access')
      .to_return(
        status: 200,
        body: JSON.generate(token_response),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.slug' do
    it 'returns gitlab' do
      expect(described_class.slug).to eq('gitlab')
    end
  end

  describe '.assume_models_exist?' do
    it 'returns true' do
      expect(described_class.assume_models_exist?).to be true
    end
  end

  describe '.configuration_options' do
    it 'includes gitlab_api_key, gitlab_instance_url, gitlab_gateway_url' do
      expect(described_class.configuration_options).to eq(%i[gitlab_api_key gitlab_instance_url gitlab_gateway_url])
    end
  end

  describe '.configuration_requirements' do
    it 'requires gitlab_api_key' do
      expect(described_class.configuration_requirements).to eq(%i[gitlab_api_key])
    end
  end

  describe '#complete routing' do
    let(:claude_model) do
      RubyLLM::Model::Info.new(
        id: 'duo-chat-opus-4-6',
        name: 'Duo Chat Opus',
        provider: 'gitlab',
        capabilities: %w[function_calling streaming],
        modalities: { input: %w[text], output: %w[text] }
      )
    end

    let(:gpt_model) do
      RubyLLM::Model::Info.new(
        id: 'duo-chat-gpt-5-1',
        name: 'Duo Chat GPT 5.1',
        provider: 'gitlab',
        capabilities: %w[function_calling streaming],
        modalities: { input: %w[text], output: %w[text] }
      )
    end

    it 'routes Claude models to AnthropicDelegate' do
      delegate = instance_double(RubyLLM::Providers::GitLab::AnthropicDelegate)
      allow(RubyLLM::Providers::GitLab::AnthropicDelegate).to receive(:new).and_return(delegate)
      allow(delegate).to receive(:complete).and_return(:anthropic_response)

      result = provider.complete([], tools: {}, temperature: 0.7, model: claude_model)
      expect(result).to eq(:anthropic_response)
      expect(delegate).to have_received(:complete)
    end

    it 'routes GPT models to OpenAIDelegate' do
      delegate = instance_double(RubyLLM::Providers::GitLab::OpenAIDelegate)
      allow(RubyLLM::Providers::GitLab::OpenAIDelegate).to receive(:new).and_return(delegate)
      allow(delegate).to receive(:complete).and_return(:openai_response)

      result = provider.complete([], tools: {}, temperature: 0.7, model: gpt_model)
      expect(result).to eq(:openai_response)
      expect(delegate).to have_received(:complete)
    end
  end

  describe '#list_models' do
    it 'returns all 8 models' do
      models = provider.list_models
      expect(models.size).to eq(8)
    end

    it 'returns Model::Info instances' do
      models = provider.list_models
      expect(models).to all(be_a(RubyLLM::Model::Info))
    end

    it 'sets provider to gitlab' do
      models = provider.list_models
      expect(models.map(&:provider)).to all(eq('gitlab'))
    end

    it 'includes expected model IDs' do
      ids = provider.list_models.map(&:id)
      expect(ids).to include('duo-chat-opus-4-6', 'duo-chat-gpt-5-1')
    end
  end

  describe '#test_connection' do
    it 'returns true when token fetch succeeds' do
      expect(provider.test_connection).to be true
    end

    it 'returns false when token fetch fails' do
      WebMock.reset!
      stub_request(:post, 'https://gitlab.com/api/v4/ai/third_party_agents/direct_access')
        .to_return(status: 401, body: 'Unauthorized')

      expect(provider.test_connection).to be false
    end
  end

  describe 'registration' do
    it 'is registered as :gitlab provider' do
      expect(RubyLLM::Provider.resolve(:gitlab)).to eq(described_class)
    end
  end

  describe 'missing configuration' do
    it 'raises ConfigurationError when gitlab_api_key is missing' do
      RubyLLM.configure { |c| c.gitlab_api_key = nil }
      expect { described_class.new(RubyLLM.config) }.to raise_error(RubyLLM::ConfigurationError)
    end
  end
end
