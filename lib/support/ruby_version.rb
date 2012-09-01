# Go ahead and fail if not using Ruby 1.9.3, no since in letting people 
# squarm for answers
if RUBY_VERSION =~ /([\d]+)\.([\d]+)\.([\d]+)/ && $1.to_i <= 1 && $2.to_i <= 9 && $3.to_i <= 2
  module Mongoid
    class RubyVersionError < RuntimeError; end
  end

  puts "\n\n\nRuby Version Error: Mongoid 3 requires Ruby 1.9.3+; you are currently using #{RUBY_VERSION}."
  puts "                    Please check your environments documentation for upgrading to Ruby 1.9.3\n\n\n"

  raise Mongoid::RubyVersionError
end
