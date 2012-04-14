source "http://rubygems.org"
gemspec

gem "rake"

platforms :mri_19 do
  unless ENV["CI"]
    gem "debugger"
    gem "perftools.rb"
  end
end
