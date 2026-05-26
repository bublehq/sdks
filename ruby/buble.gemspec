# frozen_string_literal: true

require_relative 'lib/buble/version'

Gem::Specification.new do |spec|
  spec.name = 'buble'
  spec.version = Buble::VERSION
  spec.summary = 'Official Ruby SDK for the Buble public API.'
  spec.description = 'Official Ruby SDK for Buble media generation, app workflows, file uploads, ' \
                     'and OpenAI, Anthropic, and Gemini-compatible chat endpoints.'
  spec.authors = ['Buble']
  spec.homepage = 'https://buble.ai/'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'homepage_uri' => 'https://buble.ai/',
    'documentation_uri' => 'https://buble.ai/docs',
    'source_code_uri' => 'https://github.com/bublehq/sdks/tree/main/ruby',
    'bug_tracker_uri' => 'https://github.com/bublehq/sdks/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir[
    'lib/**/*.rb',
    'README.md',
    'LICENSE',
    'docs/**/*.md',
    'examples/**/*.rb',
    'tools/**/*.rb'
  ]
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rubocop', '~> 1.60'
end
