# frozen_string_literal: true

module RubyLLM
  module Providers
    class GitLab
      class TokenManager
        CACHE_DURATION = 25 * 60 # 25 minutes
        DEFAULT_INSTANCE_URL = 'https://gitlab.com'
        DEFAULT_GATEWAY_URL = 'https://cloud.gitlab.com'
        TOKEN_PATH = '/api/v4/ai/third_party_agents/direct_access'

        def initialize(config)
          @config = config
          @mutex = Mutex.new
          @cached_token = nil
          @cached_headers = nil
          @cached_at = nil
        end

        def token
          refresh_if_needed
          @cached_token
        end

        def gateway_headers
          refresh_if_needed
          @cached_headers
        end

        def invalidate!
          @mutex.synchronize do
            @cached_token = nil
            @cached_headers = nil
            @cached_at = nil
          end
        end

        def anthropic_base_url
          "#{gateway_url}/ai/v1/proxy/anthropic"
        end

        def openai_base_url
          "#{gateway_url}/ai/v1/proxy/openai/v1"
        end

        private

        def refresh_if_needed
          @mutex.synchronize do
            fetch_token if stale?
          end
        end

        def stale?
          @cached_at.nil? || (Time.now - @cached_at) > CACHE_DURATION
        end

        def fetch_token
          response = request_direct_access
          body = response.body

          @cached_token = body['token']
          # SECURITY: Filter out x-api-key — gateway auth uses Bearer token only
          raw_headers = body.fetch('headers', {})
          @cached_headers = raw_headers.reject { |k, _| k.downcase == 'x-api-key' }
          @cached_at = Time.now
        rescue Faraday::Error => e
          raise RubyLLM::ConfigurationError,
                "Failed to obtain GitLab direct access token: #{e.message}"
        end

        def request_direct_access
          connection.post(TOKEN_PATH) do |req|
            req.headers['Authorization'] = "Bearer #{pat}"
            req.headers['Content-Type'] = 'application/json'
            req.body = JSON.generate(feature_flags: { DuoAgentPlatformNext: true })
          end
        end

        def connection
          @connection ||= RubyLLM::Connection.basic do |f|
            f.url_prefix = instance_url
            f.request :json
            f.response :json
            f.adapter :net_http
          end
        end

        def pat
          @config.gitlab_api_key
        end

        def instance_url
          @config.respond_to?(:gitlab_instance_url) && @config.gitlab_instance_url || DEFAULT_INSTANCE_URL
        end

        def gateway_url
          @config.respond_to?(:gitlab_gateway_url) && @config.gitlab_gateway_url || DEFAULT_GATEWAY_URL
        end
      end
    end
  end
end
