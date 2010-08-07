# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class One < Relations::Proxy

        # Instantiate a new embeds_one relation.
        #
        # Options:
        #
        # target: The target [child document] of the relation.
        # metadata: The relation's metadata
        def initialize(target, metadata)
          init(target, metadata)
        end
      end
    end
  end
end
