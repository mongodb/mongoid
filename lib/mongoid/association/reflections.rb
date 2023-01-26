# frozen_string_literal: true

module Mongoid
  module Association

    # The reflections module provides convenience methods that can retrieve
    # useful information about associations.
    module Reflections
      extend ActiveSupport::Concern

      # Returns the association metadata for the supplied name.
      #
      # @example Find association metadata by name.
      #   person.reflect_on_association(:addresses)
      #
      # @param [ String | Symbol ] name The name of the association to find.
      #
      # @return [ Association ] The matching association metadata.
      def reflect_on_association(name)
        self.class.reflect_on_association(name)
      end

      # Returns all association metadata for the supplied macros.
      #
      # @example Find multiple association metadata by macro.
      #   person.reflect_on_all_associations(:embeds_many)
      #
      # @param [ Symbol... ] *macros The association macros.
      #
      # @return [ Array<Association> ] The matching association metadata.
      def reflect_on_all_association(*macros)
        self.class.reflect_on_all_associations(*macros)
      end

      module ClassMethods

        # Returns the association metadata for the supplied name.
        #
        # @example Find association metadata by name.
        #   Person.reflect_on_association(:addresses)
        #
        # @param [ String | Symbol ] name The name of the association to find.
        #
        # @return [ Association ] The matching association metadata.
        def reflect_on_association(name)
          relations[name.to_s]
        end

        # Returns all association metadata for the supplied macros.
        #
        # @example Find multiple association metadata by macro.
        #   Person.reflect_on_all_associations(:embeds_many)
        #
        # @param [ Symbol... ] *macros The association macros.
        #
        # @return [ Array<Association> ] The matching association metadata.
        def reflect_on_all_associations(*macros)
          all_associations = relations.values
          unless macros.empty?
            all_associations.select! do |reflection|
              macros.include?(Association::MACRO_MAPPING.key(reflection.class))
            end
          end
          all_associations
        end
      end
    end
  end
end
