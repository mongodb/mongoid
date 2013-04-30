source "https://rubygems.org"
gemspec

gem "rake"

group :test do
  gem "rspec", "~> 2.13"

  unless ENV["CI"]
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
