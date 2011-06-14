# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Custom #:nodoc:
      # Defines the behaviour for time fields.
      class Time
        include Definable
      end
    end
  end
end
