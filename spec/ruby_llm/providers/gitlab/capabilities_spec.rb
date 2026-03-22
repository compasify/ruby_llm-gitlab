# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::GitLab::Capabilities do
  describe '.actual_model' do
    it 'returns upstream model for duo-chat-opus-4-6' do
      expect(described_class.actual_model('duo-chat-opus-4-6')).to eq('claude-opus-4-6')
    end

    it 'returns upstream model for duo-chat-sonnet-4-6' do
      expect(described_class.actual_model('duo-chat-sonnet-4-6')).to eq('claude-sonnet-4-6')
    end

    it 'returns upstream model for duo-chat-opus-4-5' do
      expect(described_class.actual_model('duo-chat-opus-4-5')).to eq('claude-opus-4-5-20251101')
    end

    it 'returns upstream model for duo-chat-sonnet-4-5' do
      expect(described_class.actual_model('duo-chat-sonnet-4-5')).to eq('claude-sonnet-4-5-20250929')
    end

    it 'returns upstream model for duo-chat-haiku-4-5' do
      expect(described_class.actual_model('duo-chat-haiku-4-5')).to eq('claude-haiku-4-5-20251001')
    end

    it 'returns upstream model for duo-chat-gpt-5-1' do
      expect(described_class.actual_model('duo-chat-gpt-5-1')).to eq('gpt-5.1-2025-11-13')
    end

    it 'returns upstream model for duo-chat-gpt-5-2' do
      expect(described_class.actual_model('duo-chat-gpt-5-2')).to eq('gpt-5.2-2025-12-11')
    end

    it 'returns upstream model for duo-chat-gpt-5-mini' do
      expect(described_class.actual_model('duo-chat-gpt-5-mini')).to eq('gpt-5-mini-2025-08-07')
    end

    it 'returns nil for unknown model' do
      expect(described_class.actual_model('unknown-model')).to be_nil
    end
  end

  describe '.anthropic_model?' do
    it 'returns true for Claude models' do
      %w[duo-chat-opus-4-6 duo-chat-sonnet-4-6 duo-chat-opus-4-5 duo-chat-sonnet-4-5 duo-chat-haiku-4-5].each do |model|
        expect(described_class.anthropic_model?(model)).to be(true), "expected #{model} to be anthropic"
      end
    end

    it 'returns false for GPT models' do
      %w[duo-chat-gpt-5-1 duo-chat-gpt-5-2 duo-chat-gpt-5-mini].each do |model|
        expect(described_class.anthropic_model?(model)).to be(false), "expected #{model} not to be anthropic"
      end
    end

    it 'returns false for unknown models' do
      expect(described_class.anthropic_model?('unknown')).to be(false)
    end
  end

  describe '.openai_model?' do
    it 'returns true for GPT models' do
      %w[duo-chat-gpt-5-1 duo-chat-gpt-5-2 duo-chat-gpt-5-mini].each do |model|
        expect(described_class.openai_model?(model)).to be(true), "expected #{model} to be openai"
      end
    end

    it 'returns false for Claude models' do
      %w[duo-chat-opus-4-6 duo-chat-sonnet-4-6 duo-chat-haiku-4-5].each do |model|
        expect(described_class.openai_model?(model)).to be(false), "expected #{model} not to be openai"
      end
    end

    it 'returns false for unknown models' do
      expect(described_class.openai_model?('unknown')).to be(false)
    end
  end

  describe 'MODEL_MAPPINGS' do
    it 'has 8 entries' do
      expect(described_class::MODEL_MAPPINGS.size).to eq(8)
    end

    it 'is frozen' do
      expect(described_class::MODEL_MAPPINGS).to be_frozen
    end

    it 'has 5 Anthropic models' do
      expect(described_class::ANTHROPIC_MODELS.size).to eq(5)
    end

    it 'has 3 OpenAI models' do
      expect(described_class::OPENAI_MODELS.size).to eq(3)
    end

    it 'ANTHROPIC_MODELS is frozen' do
      expect(described_class::ANTHROPIC_MODELS).to be_frozen
    end

    it 'OPENAI_MODELS is frozen' do
      expect(described_class::OPENAI_MODELS).to be_frozen
    end
  end
end
