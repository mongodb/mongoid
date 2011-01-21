# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module NestedAttributes #:nodoc:
        class Many < NestedBuilder

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # This attempts to perform 3 operations, either one of an update of
          # the existing relation, a replacement of the relation with a new
          # document, or a removal of the relation.
          #
          # Example:
          #
          # <tt>many.build(person)</tt>
          #
          # Options:
          #
          # parent: The parent document of the relation.
          def build(parent)
            @existing = parent.send(metadata.name)
            if over_limit?(attributes)
              raise Errors::TooManyNestedAttributeRecords.new(existing, options[:limit])
            end
            attributes.each { |attrs| process(attrs[1]) }
          end

          # Create the new builder for nested attributes on one-to-one
          # relations.
          #
          # Example:
          #
          # <tt>One.new(metadata, attributes, options)</tt>
          #
          # Options:
          #
          # metadata: The relation metadata
          # attributes: The attributes hash to attempt to set.
          # options: The options defined.
          #
          # Returns:
          #
          # A new builder.
          def initialize(metadata, attributes, options = {})
            @attributes = attributes.with_indifferent_access.sort do |a, b|
              a[0] <=> b[0]
            end
            @metadata = metadata
            @options = options
          end

          private

          # Can the existing relation potentially be deleted?
          #
          # Example:
          #
          # <tt>destroyable?({ :_destroy => "1" })</tt>
          #
          # Options:
          #
          # attributes: The attributes to pull the flag from.
          #
          # Returns:
          #
          # True if the relation can potentially be deleted.
          def destroyable?(attributes)
            destroy = attributes.delete(:_destroy)
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Are the supplied attributes of greater number than the supplied
          # limit?
          #
          # Example:
          #
          # <tt>builder.over_limit?({ "street" => "Bond" })</tt>
          #
          # Options:
          #
          # attributes: The attributes being set.
          #
          # Returns:
          #
          # True if a limit supplied and the attributes are of greater number.
          def over_limit?(attributes)
            limit = options[:limit]
            limit ? attributes.size > limit : false
          end

          # Process each set of attributes one at a time for each potential
          # new, existing, or ignored document.
          #
          # Example:
          #
          # <tt>builder.process({ "id" => 1, "street" => "Bond" })
          #
          # Options:
          #
          # attrs: The single document attributes to process.
          def process(attrs)
            return if reject?(attrs)
            if attrs[:id]
              document = existing.find(convert_id(attrs[:id]))
              destroyable?(attrs) ? document.destroy : document.update_attributes(attrs)
            else
              # @todo: Durran: Tell the push not to save the base and call it
              #   after all processing is done. This is related to #581.
              existing.push(metadata.klass.new(attrs)) unless destroyable?(attrs)
            end
          end
        end
      end
    end
  end
end
