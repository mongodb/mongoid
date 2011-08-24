# encoding: utf-8
module Mongoid #:nodoc:

  module Timestamps
    # This module handles the behaviour for return the time
    # based on utc
    module Timer 
      def self.time
        Time.now.utc? ? Time.now.utc : Time.now.getlocal
      end
    end
  end
end
