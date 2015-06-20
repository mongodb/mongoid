source "https://rubygems.org"

gemspec

gem "rake"
gem "actionpack",  "~> 4.0.12"
gem "activemodel", "~> 4.0.12"
gem "mongo", github: "mongodb/mongo-ruby-driver"

group :test do
  gem "rspec", "~> 3.1.0"

  if ENV["CI"]
    gem "coveralls", require: false
  end
end
