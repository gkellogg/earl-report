source "https://rubygems.org"

gemspec

gem 'rdf',        github: "ruby-rdf/rdf", branch: "develop"
gem 'rdf-turtle', github: "ruby-rdf/rdf-turtle", branch: "develop"
gem 'json-ld',    github: "ruby-rdf/json-ld", branch: "develop"
gem 'ebnf',       github: "gkellogg/ebnf", branch: "develop"

group :develop do
  gem "byebug", platforms: :mri
end

group :develop, :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'psych', :platforms => [:mri, :rbx]
end