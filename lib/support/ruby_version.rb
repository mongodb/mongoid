# Go ahead and fail if not using Ruby 1.9.3, no since in letting people
# squarm for answers
def raise_version_error(message)
  puts message
  Rails.logger.info(message) if defined?(Rails) && Rails.logger
  raise
end

def invalid_version?
  RUBY_VERSION =~ /([\d]+)\.([\d]+)\.([\d]+)/
  major, minor, revision = $1.to_i, $2.to_i, $3.to_i
  if defined?(JRUBY_VERSION)
    major <= 1 && minor <= 9 && revision <= 1
  else
    major <= 1 && minor <= 9 && revision <= 2
  end
end

if invalid_version?
  message = %{
Mongoid requires MRI version 1.9.3+ or JRuby 1.6.0+ running in 1.9 mode.
Your current Ruby version is defined as #{RUBY_VERSION}. Please see:
http://mongoid.org/en/mongoid/docs/tips.html#ruby for details.
  }
  raise_version_error(message)
end
