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

        class << self

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Embedded::One.macro</tt>
          #
          # Returns:
          #
          # <tt>:embeds_one</tt>
          def macro
            :embeds_one
          end
        end
      end
    end
  end
end
