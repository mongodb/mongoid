source "https://rubygems.org"
gemspec

gem "rake"
gem 'moped', github: 'mongoid/moped'

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
