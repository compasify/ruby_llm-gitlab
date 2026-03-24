# frozen_string_literal: true

require 'delegate'

module RubyLLM
  module Providers
    class GitLab
      module Chat
        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil,
                           thinking: nil, tool_prefs: nil)
          super(messages, tools: tools, temperature: temperature, model: ModelIdProxy.new(model),
                stream: stream, schema: schema, thinking: thinking, tool_prefs: tool_prefs)
        end
      end

      class ModelIdProxy < SimpleDelegator
        def id
          Capabilities.actual_model(__getobj__.id) || __getobj__.id
        end
      end
    end
  end
end
