source "https://rubygems.org"

gemspec

gem 'rdf', git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"
gem 'rdf-turtle', git: "git://github.com/ruby-rdf/rdf-turtle.git", branch: "develop"
gem 'json-ld', git: "git://github.com/ruby-rdf/json-ld.git", branch: "develop"
gem 'ebnf', git: "git://github.com/gkellogg/ebnf.git", branch: "develop"

group :develop do
  gem "wirble"
  gem "byebug", platforms: :mri
end

group :develop, :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'psych', :platforms => [:mri, :rbx]
end