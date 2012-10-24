source "http://rubygems.org"
gemspec

gem "rake"

platforms :mri_18 do
  unless ENV["CI"]
    gem "ruby-debug"
  end
  gem "SystemTimer"
end

platforms :mri_19 do
  unless ENV["CI"]
    gem "debugger"
  end
end
