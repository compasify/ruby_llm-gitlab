# frozen_string_literal: true

require 'ruby_llm'

require_relative 'ruby_llm/providers/gitlab/version'
require_relative 'ruby_llm/providers/gitlab/capabilities'
require_relative 'ruby_llm/providers/gitlab/token_manager'
require_relative 'ruby_llm/providers/gitlab/chat'
require_relative 'ruby_llm/providers/gitlab/anthropic'
require_relative 'ruby_llm/providers/gitlab/openai'

RubyLLM::Provider.register :gitlab_anthropic, RubyLLM::Providers::GitLab::Anthropic
RubyLLM::Provider.register :gitlab_openai, RubyLLM::Providers::GitLab::OpenAI
