source "http://rubygems.org"
gemspec

gem "rake"

platforms :mri_19 do
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug"
  end
end
