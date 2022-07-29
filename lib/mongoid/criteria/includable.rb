# frozen_string_literal: true

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
      # @param [ [ Symbol | Hash ]... ] *relations The names of the association(s)
      #   to eager load.
      #
      # @return [ Criteria ] The cloned criteria.
      def includes(*relations)
        extract_includes_list(klass, nil, relations)
        clone
      end

      # Get a list of criteria that are to be executed for eager loading.
      #
      # @return [ Array<Association> ] The inclusions.
      def inclusions
        @inclusions ||= []
      end

      # Set the inclusions for the criteria.
      #
      # @param [ Array<Association> ] value The inclusions.
      #
      # @return [ Array<Association> ] The new inclusions.
      def inclusions=(value)
        @inclusions = value
      end

      private

      # Add an inclusion definition to the list of inclusions for the criteria.
      #
      # @param [ Association ] association The association.
      # @param [ String ] parent The name of the association above this one in
      #   the inclusion tree, if it is a nested inclusion.
      def add_inclusion(association, parent = nil)
        if assoc = inclusions.detect { |a| a == association }
          assoc.parent_inclusions.push(parent) if parent
        else
          assoc = association.dup
          assoc.parent_inclusions = []
          assoc.parent_inclusions.push(parent) if parent
          inclusions.push(assoc)
        end
      end

      # Iterate through the list of relations and create the inclusions list.
      #
      # @param [ Class | String | Symbol ] _parent_class The class from which the
      #   association originates.
      # @param [ String ] parent The name of the association above this one in
      #   the inclusion tree, if it is a nested inclusion.
      # @param [ [ Symbol | Hash | Array<Symbol | Hash> ]... ] *relations_list
      #   The names of the association(s) to eager load.
      def extract_includes_list(_parent_class, parent, *relations_list)
        relations_list.flatten.each do |relation_object|
          if relation_object.is_a?(Hash)
            relation_object.each do |relation, _includes|
              association = _parent_class.reflect_on_association(relation)
              raise Errors::InvalidIncludes.new(_klass, [ relation ]) unless association
              add_inclusion(association, parent)
              extract_includes_list(association.klass, association.name, _includes)
            end
          else
            association = _parent_class.reflect_on_association(relation_object)
            raise Errors::InvalidIncludes.new(_parent_class, [ relation_object ]) unless association
            add_inclusion(association, parent)
          end
        end
      end
    end
  end
end
