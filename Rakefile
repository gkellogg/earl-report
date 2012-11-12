#!/usr/bin/env ruby

namespace :gem do
  desc "Build the earl-report-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build earl-report.gemspec && mv earl-report-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the earl-report-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/earl-report-#{File.read('VERSION').chomp}.gem"
  end
end

desc 'Default: run specs.'
task :default => :spec
task :specs => :spec

require 'rspec/core/rake_task'
desc 'Run specifications'
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = %w(--options spec/spec.opts) if File.exists?('spec/spec.opts')
end

desc "Run specs through RCov"
RSpec::Core::RakeTask.new("spec:rcov") do |spec|
  spec.rcov = true
  spec.rcov_opts =  %q[--exclude "spec"]
end

desc "Generate HTML report specs"
RSpec::Core::RakeTask.new("doc:spec") do |spec|
  spec.rspec_opts = ["--format", "html", "-o", "doc/spec.html"]
end

require 'yard'
namespace :doc do
  YARD::Rake::YardocTask.new
end
