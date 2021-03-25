$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require "bundler/setup"
require 'rspec'
require 'rspec/its'
require 'amazing_print'
require 'nokogumbo'

begin
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError => e
  STDERR.puts "Coverage Skipped: #{e.message}"
end

require 'earl_report'

JSON_STATE = JSON::State.new(
  :indent       => "  ",
  :space        => " ",
  :space_before => "",
  :object_nl    => "\n",
  :array_nl     => "\n"
)

::RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end

RSpec::Matchers.define :be_valid_html do
  match do |actual|
    root = Nokogiri::HTML5(actual, max_parse_errors: 1000)
    @errors = Array(root && root.errors.map(&:to_s))
    @errors.empty?
  end
  
  failure_message do |actual|
    "expected no errors, was #{@errors.join("\n")}"
  end
end
