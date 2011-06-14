# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Custom #:nodoc:
      # Defines the behaviour for hash fields.
      class Hash
        include Definable
      end
    end
  end
end
