# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::ModelIdProxy do
  let(:model) do
    double('Model',
           id: 'duo-chat-sonnet-4-6',
           max_tokens: 8192,
           context_window: 200_000,
           type: 'chat',
           supports_vision: true)
  end

  subject(:proxy) { described_class.new(model) }

  describe '#id' do
    it 'returns mapped model ID for known GitLab model' do
      expect(proxy.id).to eq('claude-sonnet-4-6')
    end

    context 'when model has no mapping' do
      let(:model) do
        double('Model',
               id: 'unknown-model',
               max_tokens: 4096,
               context_window: 128_000,
               type: 'chat',
               supports_vision: false)
      end

      it 'returns original model ID' do
        expect(proxy.id).to eq('unknown-model')
      end
    end

    context 'with OpenAI model' do
      let(:model) do
        double('Model',
               id: 'duo-chat-gpt-5-1',
               max_tokens: 16_384,
               context_window: 128_000,
               type: 'chat',
               supports_vision: true)
      end

      it 'returns mapped OpenAI model ID' do
        expect(proxy.id).to eq('gpt-5.1-2025-11-13')
      end
    end
  end

  describe 'delegation' do
    it 'delegates max_tokens to underlying model' do
      expect(proxy.max_tokens).to eq(8192)
    end

    it 'delegates context_window to underlying model' do
      expect(proxy.context_window).to eq(200_000)
    end

    it 'delegates type to underlying model' do
      expect(proxy.type).to eq('chat')
    end

    it 'delegates supports_vision to underlying model' do
      expect(proxy.supports_vision).to be(true)
    end
  end
end

RSpec.describe RubyLLM::Providers::GitLab::Chat do
  let(:base_class) do
    Class.new do
      def render_payload(_messages, tools:, temperature:, model:, stream: false,
                         schema: nil, thinking: nil, tool_prefs: nil)
        model
      end
    end
  end

  let(:chat_class) do
    klass = Class.new(base_class)
    klass.include(RubyLLM::Providers::GitLab::Chat)
    klass
  end

  let(:model) do
    double('Model',
           id: 'duo-chat-sonnet-4-6',
           max_tokens: 8192,
           context_window: 200_000)
  end

  subject(:provider) { chat_class.new }

  describe '#render_payload' do
    it 'wraps model in ModelIdProxy' do
      result = provider.render_payload([], tools: [], temperature: 0.7, model: model)
      expect(result).to be_a(RubyLLM::Providers::GitLab::ModelIdProxy)
    end

    it 'proxy returns mapped model ID' do
      result = provider.render_payload([], tools: [], temperature: 0.7, model: model)
      expect(result.id).to eq('claude-sonnet-4-6')
    end
  end
end
