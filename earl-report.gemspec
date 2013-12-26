#!/usr/bin/env ruby -rubygems

Gem::Specification.new do |gem|
  gem.version               = File.read('VERSION').chomp
  gem.date                  = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name                  = "earl-report"
  gem.homepage              = "http://github.com/gkellogg/earl-report"
  gem.license               = 'Public Domain' if gem.respond_to?(:license=)
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

  gem.required_ruby_version = '>= 1.9.3'
  gem.requirements          = []
  gem.add_runtime_dependency     'linkeddata',      '>= 1.1.0'
  gem.add_runtime_dependency     'rdf-turtle',      '>= 1.1.2'
  gem.add_runtime_dependency     'redcarpet',       '>= 3.0.0'
  gem.add_runtime_dependency     'nokogiri'
  gem.add_development_dependency 'rspec',           '>= 2.14.0'
  gem.add_development_dependency "equivalent-xml"
  gem.add_development_dependency 'yard' ,           '>= 0.8.7'
  gem.add_development_dependency 'rake'
  gem.post_install_message  = nil
end