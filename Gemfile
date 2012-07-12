source "http://rubygems.org"
gemspec

gem "rake"

platforms :mri_19 do
  unless ENV["CI"]
    gem "debugger"
  end
end

group :test do
  gem "rspec", "~> 2.11"

  unless ENV["CI"]
    gem "guard", "1.2.1"
    gem "guard-rspec", "~> 0.7"
  end
end
