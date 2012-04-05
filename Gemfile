source "http://rubygems.org"
gemspec

gem "rake"
gem "moped", path: "/Users/durran/work/moped"

platforms :mri_19 do
  unless ENV["CI"]
    gem 'debugger'
  end
end
