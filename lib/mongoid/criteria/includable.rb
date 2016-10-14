# encoding: utf-8
module Mongoid
  class Criteria

    # Module providing functionality for parsing (nested) inclusion definitions.
    module Includable

      # Eager loads all the provided relations. Will load all the documents
      # into the identity map whose ids match based on the extra query for the
      # ids.
      #
      # @note This will work for embedded relations that reference another
      #   collection via belongs_to as well.
      #
      # @note Eager loading brings all the documents into memory, so there is a
      #   sweet spot on the performance gains. Internal benchmarks show that
      #   eager loading becomes slower around 100k documents, but this will
      #   naturally depend on the specific application.
      #
      # @example Eager load the provided relations.
      #   Person.includes(:posts, :game)
      #
      # @param [ Array<Symbol>, Array<Hash> ] relations The names of the relations to eager
      #   load.
      #
      # @return [ Criteria ] The cloned criteria.
      #
      # @since 2.2.0
      def includes(*relations)
        extract_includes_list(klass, relations)
        clone
      end

      # Get a list of criteria that are to be executed for eager loading.
      #
      # @example Get the eager loading inclusions.
      #   Person.includes(:game).inclusions
      #
      # @return [ Array<Metadata> ] The inclusions.
      #
      # @since 2.2.0
      def inclusions
        @inclusions ||= []
      end

      # Set the inclusions for the criteria.
      #
      # @example Set the inclusions.
      #   criteria.inclusions = [ meta ]
      #
      # @param [ Array<Metadata> ] The inclusions.
      #
      # @return [ Array<Metadata> ] The new inclusions.
      #
      # @since 3.0.0
      def inclusions=(value)
        @inclusions = value
      end

      private

      # Add an inclusion definition to the list of inclusions for the criteria.
      #
      # @example Add an inclusion.
      #   criteria.add_inclusion(Person, :posts)
      #
      # @param [ Class, String, Symbol ] _klass The class or string/symbol of the class name.
      # @param [ Symbol ] relation The relation.
      #
      # @raise [ Errors::InvalidIncludes ] If no relation is found.
      #
      # @since 5.1.0
      def add_inclusion(_klass, metadata)
        inclusions.push(metadata) unless inclusions.include?(metadata)
      end

      def extract_includes_list(_parent_class, *relations_list)
        relations_list.flatten.each do |relation_object|
          if relation_object.is_a?(Hash)
            relation_object.each do |relation, _includes|
              metadata = _parent_class.reflect_on_association(relation)
              raise Errors::InvalidIncludes.new(_klass, [ relation ]) unless metadata
              add_inclusion(_parent_class, metadata)
              extract_includes_list(metadata.klass, _includes)
            end
          else
            metadata = _parent_class.reflect_on_association(relation_object)
            raise Errors::InvalidIncludes.new(_parent_class, [ relation_object ]) unless metadata
            add_inclusion(_parent_class, metadata)
          end
        end
      end
    end
  end
end
