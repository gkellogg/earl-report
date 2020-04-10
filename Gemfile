source "https://rubygems.org"

gemspec

gem 'rdf',        github: "ruby-rdf/rdf", branch: "develop"
gem 'rdf-turtle', github: "ruby-rdf/rdf-turtle", branch: "develop"
gem 'json-ld',    github: "ruby-rdf/json-ld", branch: "develop"
gem 'ebnf',       github: "dryruby/ebnf", branch: "develop"

group :develop do
  gem "byebug", platforms: :mri
end

group :develop, :test do
  gem 'simplecov',  platforms: :mri
  gem 'coveralls',  '~> 0.8', platforms: :mri
  gem 'psych', :platforms => [:mri, :rbx]
  gem 'awesome_print', github: "akshaymohite/awesome_print", branch: "ruby-2-7-0-warnings-fix"
end
