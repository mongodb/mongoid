# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class Criteria

    # Module providing functionality for parsing (nested) inclusion definitions.
    module Includable

      # Eager loads all the provided associations. Will load all the documents
      # into the identity map whose ids match based on the extra query for the
      # ids.
      #
      # @note This will work for embedded associations that reference another
      #   collection via belongs_to as well.
      #
      # @note Eager loading brings all the documents into memory, so there is a
      #   sweet spot on the performance gains. Internal benchmarks show that
      #   eager loading becomes slower around 100k documents, but this will
      #   naturally depend on the specific application.
      #
      # @example Eager load the provided associations.
      #   Person.includes(:posts, :game)
      #
      # @param [ Array<Symbol>, Array<Hash> ] relations The names of the associations to eager
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
      # @return [ Array<Association> ] The inclusions.
      #
      # @since 2.2.0
      def inclusions
        @inclusions ||= []
      end

      # Set the inclusions for the criteria.
      #
      # @example Set the inclusions.
      #   criteria.inclusions = [ association ]
      #
      # @param [ Array<Association> ] value The inclusions.
      #
      # @return [ Array<Association> ] The new inclusions.
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
      # @param [ Symbol ] association The association.
      #
      # @raise [ Errors::InvalidIncludes ] If no association is found.
      #
      # @since 5.1.0
      def add_inclusion(_klass, association)
        inclusions.push(association) unless inclusions.include?(association)
      end

      def extract_includes_list(_parent_class, *relations_list)
        relations_list.flatten.each do |relation_object|
          if relation_object.is_a?(Hash)
            relation_object.each do |relation, _includes|
              association = _parent_class.reflect_on_association(relation)
              raise Errors::InvalidIncludes.new(_klass, [ relation ]) unless association
              add_inclusion(_parent_class, association)
              extract_includes_list(association.klass, _includes)
            end
          else
            association = _parent_class.reflect_on_association(relation_object)
            raise Errors::InvalidIncludes.new(_parent_class, [ relation_object ]) unless association
            add_inclusion(_parent_class, association)
          end
        end
      end
    end
  end
end
