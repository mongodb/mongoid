source "https://rubygems.org"
gemspec

gem "rake"
gem "actionpack",  "~> 4.2.0"
gem "activemodel", "~> 4.2.0"

group :test do
  gem "rspec", "~> 3.1.0"

  if ENV["CI"]
    gem "coveralls", require: false
  end
end
