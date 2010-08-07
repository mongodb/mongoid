# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class Many < Relations::Proxy

        # Instantiate a new embeds_many relation.
        #
        # Options:
        #
        # target: The target [child document array] of the relation.
        # metadata: The relation's metadata
        def initialize(target, metadata)
          init(target, metadata)
        end
      end
    end
  end
end
