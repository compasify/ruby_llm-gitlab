# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::ModelIdProxy do
  let(:model_info) do
    RubyLLM::Model::Info.new(
      id: 'duo-chat-opus-4-6',
      name: 'Duo Chat Opus 4-6',
      provider: 'gitlab',
      capabilities: %w[function_calling streaming],
      modalities: { input: %w[text], output: %w[text] }
    )
  end

  let(:proxy) { described_class.new(model_info) }

  describe '#id' do
    it 'returns the actual model ID for known models' do
      expect(proxy.id).to eq('claude-opus-4-6')
    end

    it 'falls back to the original ID for unknown models' do
      unknown = RubyLLM::Model::Info.new(
        id: 'unknown-model',
        name: 'Unknown',
        provider: 'gitlab',
        capabilities: [],
        modalities: { input: %w[text], output: %w[text] }
      )
      expect(described_class.new(unknown).id).to eq('unknown-model')
    end
  end

  describe 'delegation' do
    it 'delegates name to the wrapped model' do
      expect(proxy.name).to eq('Duo Chat Opus 4-6')
    end

    it 'delegates provider to the wrapped model' do
      expect(proxy.provider).to eq('gitlab')
    end

    it 'delegates capabilities to the wrapped model' do
      expect(proxy.capabilities).to eq(%w[function_calling streaming])
    end
  end
end
