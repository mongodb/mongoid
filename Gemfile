source "https://rubygems.org"
gemspec

gem "rake"

group :test do
  gem "rspec", "~> 2.99.0.beta1"

  if ENV["CI"]
    gem "coveralls", require: false
  else
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
