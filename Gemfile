source "http://rubygems.org"
gemspec

gem "rake"
gem "bson", "1.6.2"
gem "bson_ext", "1.6.2"

platforms :mri_18 do
  unless ENV["CI"]
    gem "ruby-debug"
  end
  gem "SystemTimer"
end

platforms :mri_19 do
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug" if RUBY_VERSION < "1.9.3"
  end
end
