source "http://rubygems.org"
gemspec

gem 'activemodel', git: 'https://github.com/rails/rails.git', branch: '3-2-stable'

gem "rake"
gem "moped", "~> 1.5.0"

group :test do
  gem "rspec", "~> 2.12"

  unless ENV["CI"]
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
