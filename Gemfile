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
    if RUBY_VERSION < "1.9.3"
      gem "ruby-debug19",       :require => "ruby-debug"
    else
      gem "linecache19",        :git => 'git://github.com/mark-moseley/linecache.git'
      gem "ruby-debug-base19x", ">= 0.11.30.pre4"
      gem "ruby-debug19",       :require => "ruby-debug"
    end
  end
end
