# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Attributes

    # This module defines projection helpers.
    #
    # @api private
    class Projector
      def initialize(projection)
        @projection = projection
      end

      attr_reader :projection

      # Determine if the specified attribute, or a dot notation path, is allowed
      # by the configured projection, if any.
      #
      # If there is no configured projection, returns true.
      #
      # @param [ String ] name The name of the attribute or a dot notation path.
      #
      # @return [ true, false ] Whether the attribute is allowed by projection.
      #
      # @api private
      def attribute_or_path_allowed?(name)
        unless projection
          # No projection
          return true
        end

        # Projection rules are rather non-trivial. See
        # https://docs.mongodb.com/manual/reference/method/db.collection.find/#find-projection
        # for server documentation.
        # 4.4 server (and presumably all older ones) requires that a projection
        # is either exclusionary or inclusionary, i.e. one cannot mix
        # exclusions and inclusions in the same query.
        # Integer projection values other than 0 and 1 aren't officially
        # documented as of this writing; see DOCSP-15266.
        # 4.4 server also allows nested hash projection specification
        # in addition to dot notation, which I assume Mongoid doesn't handle yet.
        projection_value = projection.values.first
        inclusionary = case projection_value
        when Integer
          projection_value >= 1
        when true
          true
        when false
          false
        else
          # The various expressions that are permitted as projection arguments
          # imply an inclusionary projection.
          true
        end

        !!if inclusionary
          selection_included?(name, projection)
        else
          !selection_excluded?(name, projection)
        end
      end

      def selection_excluded?(name, selection)
        path = name.split('.')

        selection.find do |k, included|
          # check that a prefix of the field exists in excluded fields
          k_path = k.split('.')
          included == 0 && path[0, k_path.size] == k_path
        end
      end

      def selection_included?(name, selection)
        path = name.split('.')
        selection.find do |k, included|
          # check that a prefix of the field exists in included fields
          k_path = k.split('.')
          included == 1 && path[0, k_path.size] == k_path
        end
      end
    end
  end
end
