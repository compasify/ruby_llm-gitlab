# frozen_string_literal: true

require_relative 'lib/ruby_llm/providers/gitlab/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby_llm-gitlab'
  spec.version = RubyLLM::Providers::GitLab::VERSION
  spec.authors = ['Compasify']
  spec.email = ['']

  spec.summary = 'GitLab Duo AI provider for RubyLLM'
  spec.description = 'Use Claude and GPT models through your GitLab subscription via the GitLab AI Gateway.'
  spec.homepage = 'https://github.com/crmne/ruby_llm'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/crmne/ruby_llm'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', '*.gemspec']
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_llm', '>= 1.0', '< 3.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
