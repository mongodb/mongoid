# Go ahead and fail if not using Ruby 1.9.3, no since in letting people 
# squarm for answers
RUBY_VERSION =~ /([\d]+)\.([\d]+)\.([\d]+)/

major, minor, revision = $1.to_i, $2.to_i, $3.to_i

def raise_version_error(messages)

  messages.each { |m| puts m}

  if defined?(Rails)
    messages.each { |m| Rails.logger.info m }
  end

  raise
end

if defined?(JRUBY_VERSION) && major <= 1 && minor <= 9 # JRUB
  messages = []
  messages << "\n\n\nRuby Version Error: Mongoid 3 on JRuby requires Ruby 1.9.2+ compatability; start jruby with the --1.9 argument"

  raise_version_error(messages)
elsif major <= 1 && minor <= 9 && revision <= 2 # MRI
  messages = []
  messages << "\n\n\nRuby Version Error: Mongoid 3 requires Ruby 1.9.3+; you are currently using #{RUBY_VERSION}."
  messages << "                    Please check your environments documentation for upgrading to Ruby 1.9.3\n\n\n"

  raise_version_error(messages)
end
