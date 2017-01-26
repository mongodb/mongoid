# encoding: utf-8
module Mongoid
  module Relations

    # The reflections module provides convenience methods that can retrieve
    # useful information about associations.
    module Reflections
      extend ActiveSupport::Concern

      # Returns the relation metadata for the supplied name.
      #
      # @example Find relation metadata by name.
      #   person.reflect_on_association(:addresses)
      #
      # @param [ String, Symbol ] name The name of the relation to find.
      #
      # @return [ Metadata ] The matching relation metadata.
      def reflect_on_association(name)
        self.class.reflect_on_association(name)
      end

      # Returns all relation metadata for the supplied macros.
      #
      # @example Find multiple relation metadata by macro.
      #   person.reflect_on_all_associations(:embeds_many)
      #
      # @param [ Array<Symbol> ] *macros The relation macros.
      #
      # @return [ Array<Metadata> ] The matching relation metadata.
      def reflect_on_all_associations(*macros)
        self.class.reflect_on_all_associations(*macros)
      end

      module ClassMethods

        # Returns the relation metadata for the supplied name.
        #
        # @example Find relation metadata by name.
        #   Person.reflect_on_association(:addresses)
        #
        # @param [ String, Symbol ] name The name of the relation to find.
        #
        # @return [ Metadata ] The matching relation metadata.
        def reflect_on_association(name)
          relations[name.to_s]
        end

        # Returns all relation metadata for the supplied macros.
        #
        # @example Find multiple relation metadata by macro.
        #   Person.reflect_on_all_associations(:embeds_many)
        #
        # @param [ Array<Symbol> ] *macros The relation macros.
        #
        # @return [ Array<Metadata> ] The matching relation metadata.
        def reflect_on_all_associations(*macros)
          association_reflections = relations.values
          association_reflections.select! { |reflection| macros.include?(reflection.macro) } unless macros.empty?
          association_reflections
        end
      end
    end
  end
end
