# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class In < Relations::Proxy

        # Instantiate a new embedded_in relation.
        #
        # Options:
        #
        # target: The target [parent document] of the relation.
        # metadata: The relation's metadata
        def initialize(target, metadata)
          init(target, metadata)
        end
      end
    end
  end
end
