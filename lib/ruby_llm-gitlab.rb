# frozen_string_literal: true

require 'ruby_llm'
require_relative 'ruby_llm/providers/gitlab'

RubyLLM::Provider.register :gitlab, RubyLLM::Providers::GitLab
