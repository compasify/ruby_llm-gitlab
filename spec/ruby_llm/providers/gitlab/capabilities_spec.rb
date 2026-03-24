# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::Capabilities do
  describe 'MODEL_MAPPINGS' do
    it 'contains 8 model mappings' do
      expect(described_class::MODEL_MAPPINGS.size).to eq(8)
    end

    it 'maps duo-chat-opus-4-6 to claude-opus-4-6' do
      expect(described_class::MODEL_MAPPINGS['duo-chat-opus-4-6']).to eq('claude-opus-4-6')
    end

    it 'maps duo-chat-gpt-5-1 to gpt-5.1-2025-11-13' do
      expect(described_class::MODEL_MAPPINGS['duo-chat-gpt-5-1']).to eq('gpt-5.1-2025-11-13')
    end
  end

  describe 'ANTHROPIC_MODELS' do
    it 'contains 5 Claude models' do
      expect(described_class::ANTHROPIC_MODELS.size).to eq(5)
    end

    it 'includes duo-chat-opus-4-6' do
      expect(described_class::ANTHROPIC_MODELS).to include('duo-chat-opus-4-6')
    end

    it 'excludes GPT models' do
      expect(described_class::ANTHROPIC_MODELS).not_to include('duo-chat-gpt-5-1')
    end
  end

  describe 'OPENAI_MODELS' do
    it 'contains 3 GPT models' do
      expect(described_class::OPENAI_MODELS.size).to eq(3)
    end

    it 'includes duo-chat-gpt-5-1' do
      expect(described_class::OPENAI_MODELS).to include('duo-chat-gpt-5-1')
    end

    it 'excludes Claude models' do
      expect(described_class::OPENAI_MODELS).not_to include('duo-chat-opus-4-6')
    end
  end

  describe '.actual_model' do
    it 'returns the actual model ID for a known GitLab model' do
      expect(described_class.actual_model('duo-chat-opus-4-6')).to eq('claude-opus-4-6')
    end

    it 'returns nil for an unknown model' do
      expect(described_class.actual_model('unknown-model')).to be_nil
    end
  end

  describe '.anthropic_model?' do
    it 'returns true for Claude models' do
      expect(described_class.anthropic_model?('duo-chat-opus-4-6')).to be true
    end

    it 'returns false for GPT models' do
      expect(described_class.anthropic_model?('duo-chat-gpt-5-1')).to be false
    end
  end

  describe '.openai_model?' do
    it 'returns true for GPT models' do
      expect(described_class.openai_model?('duo-chat-gpt-5-1')).to be true
    end

    it 'returns false for Claude models' do
      expect(described_class.openai_model?('duo-chat-opus-4-6')).to be false
    end
  end
end
