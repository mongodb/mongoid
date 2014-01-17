source "https://rubygems.org"
gemspec

gem "rake"
gem "actionpack", "~> 4.0"

group :test do
  gem "rspec", "~> 3.0.0.beta1"

  if ENV["CI"]
    gem "coveralls", require: false
  else
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
