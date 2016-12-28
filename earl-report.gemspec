#!/usr/bin/env ruby -rubygems

Gem::Specification.new do |gem|
  gem.version               = File.read('VERSION').chomp
  gem.date                  = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name                  = "earl-report"
  gem.homepage              = "http://github.com/gkellogg/earl-report"
  gem.license               = 'Unlicense'
  gem.summary               = "Earl Report summary generator"
  gem.description           = "EarlReport generates HTML+RDFa rollups of multiple EARL reports."

  gem.authors               = ['Gregg Kellogg']
  gem.email                 = 'gregg@greggkellogg.net'

  gem.platform              = Gem::Platform::RUBY
  gem.files                 = %w(README.md VERSION) + Dir.glob('lib/**/*')
  gem.bindir               = %q(bin)
  gem.executables          = %w(earl-report)
  gem.default_executable   = gem.executables.first
  gem.require_paths         = %w(lib)
  gem.extensions            = %w()
  gem.test_files            = Dir.glob('spec/**/*.rb') + Dir.glob('spec/test-files/*')
  gem.has_rdoc              = false

  gem.required_ruby_version = '>= 2.0'
  gem.requirements          = []
  gem.add_runtime_dependency     'linkeddata',      '~> 2.0'
  gem.add_runtime_dependency     'sparql',          '~> 2.0'
  gem.add_runtime_dependency     'rdf-turtle',      '~> 2.0'
  gem.add_runtime_dependency     'json-ld',         '~> 2.1', '>= 2.1.1'
  gem.add_runtime_dependency     'redcarpet',       '~> 3.0'
  gem.add_runtime_dependency     'nokogiri',        '~> 1.6'
  gem.add_development_dependency 'rspec',           '~> 3.0'
  gem.add_development_dependency 'rspec-its',       '~> 1.0'
  gem.add_development_dependency "equivalent-xml",  '~> 0.6'
  gem.add_development_dependency 'yard' ,           '~> 0.8'
  gem.add_development_dependency 'rake',            '~> 11.0'
  gem.post_install_message  = nil
end
