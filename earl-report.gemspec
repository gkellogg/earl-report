#!/usr/bin/env ruby -rubygems

Gem::Specification.new do |gem|
  gem.version               = File.read('VERSION').chomp
  gem.date                  = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name                  = "earl-report"
  gem.homepage              = "https://github.com/gkellogg/earl-report"
  gem.license               = 'Unlicense'
  gem.summary               = "Earl Report summary generator"
  gem.description           = "EarlReport generates HTML+RDFa rollups of multiple EARL reports."
  gem.metadata              = {
    "documentation_uri" => "https://gkellogg.github.io/earl-report",
    "bug_tracker_uri"   => "https://github.com/gkellogg/earl-report/issues",
    "homepage_uri"      => "https://github.com/gkellogg/earl-report",
    "source_code_uri"   => "https://github.com/gkellogg/earl-report",
  }

  gem.authors               = ['Gregg Kellogg']
  gem.email                 = 'gregg@greggkellogg.net'

  gem.platform              = Gem::Platform::RUBY
  gem.files                 = %w(README.md VERSION) + Dir.glob('lib/**/*')
  gem.bindir               = %q(bin)
  gem.executables          = %w(earl-report)
  gem.require_paths         = %w(lib)
  gem.test_files            = Dir.glob('spec/**/*.rb') + Dir.glob('spec/test-files/*')

  gem.required_ruby_version = '>= 3.0'
  gem.requirements          = []
  gem.add_runtime_dependency     'rdf',             '~> 3.3'
  gem.add_runtime_dependency     'rdf-turtle',      '~> 3.3'
  gem.add_runtime_dependency     'rdf-vocab',       '~> 3.3'
  gem.add_runtime_dependency     'json-ld',         '~> 3.3'
  gem.add_runtime_dependency     'sparql',          '~> 3.3'
  gem.add_runtime_dependency     'haml',            '>= 6.1'
  gem.add_runtime_dependency     'kramdown',        '~> 2.4'
  gem.add_development_dependency 'htmlbeautifier',  '~> 1.4'
  gem.add_development_dependency 'nokogiri',        '~> 1.15', '>= 1.15.4'
  gem.add_development_dependency 'rdf-rdfa',        '~> 3.3'
  gem.add_development_dependency 'rspec',           '~> 3.12'
  gem.add_development_dependency 'rspec-its',       '~> 1.3'
  gem.add_development_dependency "equivalent-xml",  '~> 0.6'
  gem.add_development_dependency 'yard' ,           '~> 0.9'
  gem.add_development_dependency 'rake',            '~> 13.0'
  gem.post_install_message  = nil
end
