source "http://rubygems.org"
gemspec

gem "rake"
gem "moped", github: "mongoid/moped"

platforms :mri_19 do
  unless ENV["CI"]
    gem "debugger"
  end
end
