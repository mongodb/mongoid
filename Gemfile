source "http://rubygems.org"
gemspec

gem "rake"
gem "moped", "~> 1.3.0"

group :test do
  gem "rspec", "~> 2.11"

  unless ENV["CI"]
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
