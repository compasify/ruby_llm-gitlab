# frozen_string_literal: true

module RubyLLM
  module Providers
    class GitLab < Provider
      require_relative 'gitlab/capabilities'
      require_relative 'gitlab/token_manager'
      require_relative 'gitlab/chat'
      require_relative 'gitlab/anthropic_delegate'
      require_relative 'gitlab/openai_delegate'

      include GitLab::Chat

      def initialize(config)
        @config = config
        ensure_configured!
      end

      def complete(messages, tools:, temperature:, model:, **kwargs, &block)
        delegate_for(model).complete(messages, tools: tools, temperature: temperature, model: model, **kwargs, &block)
      end

      def list_models
        GitLab::Capabilities::MODEL_MAPPINGS.map do |gitlab_id, _actual_id|
          RubyLLM::Model::Info.new(
            id: gitlab_id,
            name: gitlab_id.tr('-', ' ').capitalize,
            provider: 'gitlab',
            capabilities: %w[function_calling streaming vision structured_output],
            modalities: { input: %w[text image], output: %w[text] }
          )
        end
      end

      def test_connection
        token_manager.token
        true
      rescue StandardError
        false
      end

      class << self
        def configuration_options = %i[gitlab_api_key gitlab_instance_url gitlab_gateway_url]
        def configuration_requirements = %i[gitlab_api_key]
        def assume_models_exist? = true
      end

      private

      def delegate_for(model)
        model_id = model.is_a?(String) ? model : model.id
        if GitLab::Capabilities.anthropic_model?(model_id)
          anthropic_delegate
        else
          openai_delegate
        end
      end

      def anthropic_delegate
        @anthropic_delegate ||= GitLab::AnthropicDelegate.new(@config)
      end

      def openai_delegate
        @openai_delegate ||= GitLab::OpenAIDelegate.new(@config)
      end

      def token_manager
        @token_manager ||= GitLab::TokenManager.new(@config)
      end
    end
  end
end
