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
    gem "guard"
    gem "guard-rspec"
    gem "rb-fsevent"
  end
end
