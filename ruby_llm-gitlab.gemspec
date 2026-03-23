# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'ruby_llm-gitlab'
  spec.version = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.authors = ['RubyLLM Contributors']
  spec.email = ['contributors@rubyllm.com']

  spec.summary = 'GitLab AI Gateway provider for RubyLLM'
  spec.description = 'Access Claude and GPT models through GitLab Duo via the RubyLLM interface. ' \
                     'One provider, automatic routing to Anthropic or OpenAI backends.'
  spec.homepage = 'https://github.com/crmne/ruby_llm'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/crmne/ruby_llm'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_llm', '>= 1.0', '< 3.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
