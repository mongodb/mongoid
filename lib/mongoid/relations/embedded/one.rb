# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class One < OneToOne

        # Instantiate a new embeds_one relation.
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child document] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata)
        end
      end
    end
  end
end
