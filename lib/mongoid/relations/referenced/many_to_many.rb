# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:
      class ManyToMany
        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.builder(meta, object)</tt>
          #
          # Options:
          #
          # meta: The metadata of the relation.
          # object: A document or attributes to build with.
          #
          # Returns:
          #
          # A newly instantiated builder object.
          def builder(meta, object)
            Builders::Referenced::ManyToMany.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            false
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.foreign_key_suffix</tt>
          #
          # Returns:
          #
          # "_id"
          def foreign_key_suffix
            "_ids"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Referenced::ManyToMany.macro</tt>
          #
          # Returns:
          #
          # <tt>:references_and_referenced_in_many</tt>
          def macro
            :references_and_referenced_in_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::Nested::ManyToMany.builder(attributes, options)</tt>
          #
          # Options:
          #
          # attributes: The attributes to build with.
          # options: The options for the builder.
          #
          # Returns:
          #
          # A newly instantiated nested builder object.
          def nested_builder(metadata, attributes, options)
            Builders::Referenced::Nested::ManyToMany.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.stores_foreign_key?</tt>
          #
          # Returns:
          #
          # true
          def stores_foreign_key?
            true
          end
        end
      end
    end
  end
end
