# frozen_string_literal: true

module RubyLLM
  module Providers
    module GitLab
      # Model mappings from gitlab-ai-provider v5.2.2 (src/model-mappings.ts).
      # Codex models excluded — they require the OpenAI Responses API which ruby_llm doesn't support.
      module Capabilities
        MODEL_MAPPINGS = {
          # Anthropic models
          'duo-chat-opus-4-6' => 'claude-opus-4-6',
          'duo-chat-sonnet-4-6' => 'claude-sonnet-4-6',
          'duo-chat-opus-4-5' => 'claude-opus-4-5-20251101',
          'duo-chat-sonnet-4-5' => 'claude-sonnet-4-5-20250929',
          'duo-chat-haiku-4-5' => 'claude-haiku-4-5-20251001',
          # OpenAI models (Chat Completions API only)
          'duo-chat-gpt-5-1' => 'gpt-5.1-2025-11-13',
          'duo-chat-gpt-5-2' => 'gpt-5.2-2025-12-11',
          'duo-chat-gpt-5-mini' => 'gpt-5-mini-2025-08-07'
        }.freeze

        ANTHROPIC_MODELS = MODEL_MAPPINGS.select { |_, v| v.start_with?('claude-') }.keys.freeze
        OPENAI_MODELS = MODEL_MAPPINGS.reject { |_, v| v.start_with?('claude-') }.keys.freeze

        module_function

        def actual_model(gitlab_model_id)
          MODEL_MAPPINGS[gitlab_model_id]
        end

        def anthropic_model?(model_id)
          ANTHROPIC_MODELS.include?(model_id)
        end

        def openai_model?(model_id)
          OPENAI_MODELS.include?(model_id)
        end
      end
    end
  end
end
