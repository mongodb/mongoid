source "https://rubygems.org"
gemspec

gem "rake"
gem 'bson', github: 'mongodb/bson-ruby', ref: '37ef7c4575'

group :test do
  gem "rspec", "~> 2.14"

  if ENV["CI"]
    gem "coveralls", require: false
  else
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
