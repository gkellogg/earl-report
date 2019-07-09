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
  gem.require_paths         = %w(lib)
  gem.test_files            = Dir.glob('spec/**/*.rb') + Dir.glob('spec/test-files/*')

  gem.required_ruby_version = '>= 2.2.2'
  gem.requirements          = []
  gem.add_runtime_dependency     'linkeddata',      '~> 3.0'
  gem.add_runtime_dependency     'haml',            '~> 5.0'
  gem.add_runtime_dependency     'kramdown',        '~> 1.14'
  gem.add_runtime_dependency     'nokogiri',        '~> 1.10'
  gem.add_development_dependency 'rspec',           '~> 3.8'
  gem.add_development_dependency 'rspec-its',       '~> 1.3'
  gem.add_development_dependency "equivalent-xml",  '~> 0.6'
  gem.add_development_dependency 'yard' ,           '~> 0.9'
  gem.add_development_dependency 'rake',            '~> 12.3'
  gem.post_install_message  = nil
end
