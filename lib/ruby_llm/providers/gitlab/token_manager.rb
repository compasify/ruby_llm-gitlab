# frozen_string_literal: true

module RubyLLM
  module Providers
    module GitLab
      # 2-step auth: PAT → direct_access token → gateway proxy.
      # Thread-safe. Cached 25min (tokens expire at 30).
      class TokenManager
        TOKEN_CACHE_TTL = 25 * 60
        DIRECT_ACCESS_PATH = '/api/v4/ai/third_party_agents/direct_access'
        DEFAULT_GATEWAY_URL = 'https://cloud.gitlab.com'

        def initialize(config)
          @config = config
          @mutex = Mutex.new
          @cached_token = nil
          @cached_headers = nil
          @token_expires_at = nil
        end

        def token
          refresh_if_needed!
          @cached_token
        end

        # SECURITY: x-api-key filtered out — Bearer auth used instead
        def gateway_headers
          refresh_if_needed!
          @cached_headers
        end

        def invalidate!
          @mutex.synchronize do
            @cached_token = nil
            @cached_headers = nil
            @token_expires_at = nil
          end
        end

        def anthropic_base_url
          "#{gateway_url}/ai/v1/proxy/anthropic"
        end

        def openai_base_url
          "#{gateway_url}/ai/v1/proxy/openai/v1"
        end

        private

        def gateway_url
          @config.gitlab_gateway_url || DEFAULT_GATEWAY_URL
        end

        def instance_url
          @config.gitlab_instance_url || 'https://gitlab.com'
        end

        def refresh_if_needed!
          @mutex.synchronize do
            return if token_valid?

            fetch_token!
          end
        end

        def token_valid?
          @cached_token && @token_expires_at && Time.now < @token_expires_at
        end

        def fetch_token!
          response = request_direct_access_token
          body = response.body
          body = JSON.parse(body) if body.is_a?(String)

          @cached_token = body['token']
          raw_headers = body['headers'] || {}

          # SECURITY: x-api-key must NOT be forwarded — Bearer token auth used instead
          @cached_headers = raw_headers.reject { |key, _| key.downcase == 'x-api-key' }
          @token_expires_at = Time.now + TOKEN_CACHE_TTL
        rescue Faraday::Error => e
          raise RubyLLM::ConfigurationError,
                "Failed to obtain GitLab AI Gateway token: #{e.message}"
        end

        def request_direct_access_token
          connection = RubyLLM::Connection.basic do |f|
            f.request :json
            f.response :json
          end

          connection.post("#{instance_url}#{DIRECT_ACCESS_PATH}") do |req|
            req.headers['Authorization'] = "Bearer #{@config.gitlab_api_key}"
            req.headers['Content-Type'] = 'application/json'
            req.body = { feature_flags: { DuoAgentPlatformNext: true } }
          end
        end
      end
    end
  end
end
