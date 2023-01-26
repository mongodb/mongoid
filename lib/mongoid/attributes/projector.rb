# frozen_string_literal: true

module Mongoid
  module Attributes

    # This module defines projection helpers.
    #
    # Projection rules are rather non-trivial. See
    # https://www.mongodb.com/docs/manual/reference/method/db.collection.find/#find-projection
    # for server documentation.
    # 4.4 server (and presumably all older ones) requires that a projection
    # for content fields is either exclusionary or inclusionary, i.e. one
    # cannot mix exclusions and inclusions in the same query.
    # However, _id can be excluded in a projection that includes content
    # fields.
    # Integer projection values other than 0 and 1 aren't officially
    # documented as of this writing; see DOCSP-15266.
    # 4.4 server also allows nested hash projection specification
    # in addition to dot notation, which I assume Mongoid doesn't handle yet.
    #
    # @api private
    class Projector
      def initialize(projection)
        if projection
          @content_projection = projection.dup
          @content_projection.delete('_id')
          @id_projection_value = projection['_id']
        else
          @content_projection = nil
          @id_projection_value = nil
        end
      end

      attr_reader :id_projection_value
      attr_reader :content_projection

      # Determine if the specified attribute, or a dot notation path, is allowed
      # by the configured projection, if any.
      #
      # If there is no configured projection, returns true.
      #
      # @param [ String ] name The name of the attribute or a dot notation path.
      #
      # @return [ true | false ] Whether the attribute is allowed by projection.
      #
      # @api private
      def attribute_or_path_allowed?(name)
        # Special handling for _id.
        if name == '_id'
          result = unless id_projection_value.nil?
            value_inclusionary?(id_projection_value)
          else
            true
          end
          return result
        end

        if content_projection.nil?
          # No projection (as opposed to an empty projection).
          # All attributes are allowed.
          return true
        end

        # Find an item which matches or is a parent of the requested name/path.
        # This handles the case when, for example, the projection was
        # {foo: true} and we want to know if foo.bar is allowed.
        item, value = content_projection.detect do |path, value|
          (name + '.').start_with?(path + '.')
        end
        if item
          return value_inclusionary?(value)
        end

        if content_inclusionary?
          # Find an item which would be a strict child of the requested name/path.
          # This handles the case when, for example, the projection was
          # {"foo.bar" => true} and we want to know if foo is allowed.
          # (It is as a container of bars.)
          item, value = content_projection.detect do |path, value|
            (path + '.').start_with?(name + '.')
          end
          if item
            return true
          end
        end

        !content_inclusionary?
      end

      private

      # Determines whether the projection for content fields is inclusionary.
      #
      # An empty projection is inclusionary.
      def content_inclusionary?
        if content_projection.empty?
          return value_inclusionary?(id_projection_value)
        end

        value_inclusionary?(content_projection.values.first)
      end

      def value_inclusionary?(value)
        case value
        when Integer
          value >= 1
        when true
          true
        when false
          false
        else
          # The various expressions that are permitted as projection arguments
          # imply an inclusionary projection.
          true
        end
      end
    end
  end
end
