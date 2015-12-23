# encoding: utf-8
module Mongoid
  class Criteria

    # Module providing functionality for parsing (nested) inclusion definitions.
    module Includable

      # Add an inclusion definition to the list of inclusions for the criteria.
      #
      # @example Add an inclusion.
      #   criteria.add_inclusion(Person, :posts)
      #
      # @param [ Class, String, Symbol ] k The class or string/symbol of the class name.
      # @param [ Symbol ] relation The relation.
      #
      # @raise [ Errors::InvalidIncludes ] If no relation is found.
      #
      # @since 5.1.0
      def add_inclusion(k, relation)
        metadata = get_inclusion_metadata(k, relation)
        raise Errors::InvalidIncludes.new(k, [ relation ]) unless metadata
        inclusions.push(metadata) unless inclusions.include?(metadata)
      end

      # Extract inclusion definitions from a list.
      #
      # @example Extract the inclusions from a list.
      #   criteria.extract_relations_list(:posts, [{ :alerts => :items }])
      #
      # @param [ Symbol ] association The name of the association.
      # @param [ Array, Symbol ] relations Either the relation name or a list of associations.
      #
      # @since 5.1.0
      def extract_relations_list(association, relations)
        relations.each do |r|
          if r.is_a?(Hash)
            extract_nested_inclusion(association, r)
          else
            add_inclusion(association, r)
          end
        end
      end

      # Extract nested inclusion.
      #
      # @example Extract the inclusions from a nested definition.
      #   criteria.extract_nested_inclusion(User, { :posts => [:alerts] })
      #
      # @param [ Class, Symbol ] c The class for which the inclusion should be added.
      # @param [ Hash ] relation The nested inclusion.
      #
      # @since 5.1.0
      def extract_nested_inclusion(c, relation)
        relation.each do |k, v|
          add_inclusion(c, k)
          if v.is_a?(Array)
            extract_relations_list(k, v)
          else
            add_inclusion(k, v)
          end
        end
      end

      # Get the metadata for an inclusion.
      #
      # @example Get the metadata for an inclusion definition.
      #   criteria.get_inclusion_metadata(User, :posts)
      #
      # @param [ Class, Symbol, String ] k The class for determining the association metadata
      # @param [ Symbol  ] association The name of the association.
      #
      # @since 5.1.0
      def get_inclusion_metadata(k, association)
        if k.is_a?(Class)
          k.reflect_on_association(association)
        else
          k.to_s.classify.constantize.reflect_on_association(association)
        end
      end
    end
  end
end
