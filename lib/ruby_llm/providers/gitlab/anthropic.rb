# frozen_string_literal: true

module RubyLLM
  module Providers
    module GitLab
      class Anthropic < RubyLLM::Providers::Anthropic
        include GitLab::Chat

        def api_base
          token_manager.anthropic_base_url
        end

        def headers
          {
            'Authorization' => "Bearer #{token_manager.token}",
            'anthropic-version' => '2023-06-01'
          }.merge(token_manager.gateway_headers)
        end

        def complete(...)
          super
        rescue RubyLLM::UnauthorizedError
          token_manager.invalidate!
          super
        end

        class << self
          def slug
            'gitlab_anthropic'
          end

          def configuration_options
            %i[gitlab_api_key gitlab_instance_url gitlab_gateway_url]
          end

          def configuration_requirements
            %i[gitlab_api_key]
          end

          def assume_models_exist?
            true
          end
        end

        private

        def token_manager
          @token_manager ||= TokenManager.new(@config)
        end
      end
    end
  end
end
