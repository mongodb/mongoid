source "https://rubygems.org"
gemspec

gem "rake"
gem "actionpack",  "~> 4.1.1"
gem "activemodel", "~> 4.1.1"

group :test do
  gem "rspec", "~> 3.0.0"

  if ENV["CI"]
    gem "coveralls", require: false
  else
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
