# frozen_string_literal: true

require 'webmock/rspec'
require 'ruby_llm-gitlab'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.order = :random

  config.before do
    RubyLLM.configure do |c|
      c.gitlab_api_key = 'glpat-test-token'
      c.gitlab_instance_url = nil
      c.gitlab_gateway_url = nil
    end
  end
end
