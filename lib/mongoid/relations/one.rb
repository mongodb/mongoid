# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This is the superclass for one to one relations and defines the common
    # behaviour or those proxies.
    class One < Proxy

      def in_memory
        [ target ]
      end
    end
  end
end
