# encoding: utf-8
require "mongoid/relations/cascading/delete"
require "mongoid/relations/cascading/destroy"
require "mongoid/relations/cascading/nullify"
require "mongoid/relations/cascading/restrict"

module Mongoid
  module Relations

    # This module defines the behaviour for setting up cascading deletes and
    # nullifies for relations, and how to delegate to the approriate strategy.
    module Cascading
      extend ActiveSupport::Concern

      included do
        class_attribute :cascades
        self.cascades = []
      end

      # Perform all cascading deletes, destroys, or nullifies. Will delegate to
      # the appropriate strategy to perform the operation.
      #
      # @example Execute cascades.
      #   document.cascade!
      #
      # @since 2.0.0.rc.1
      def cascade!
        cascades.each do |name|
          if !metadata || !metadata.versioned?
            if meta = relations[name]
              strategy = meta.cascade_strategy
              strategy.new(self, meta).cascade if strategy
            end
          end
        end
      end

      module ClassMethods

        # Attempt to add the cascading information for the document to know how
        # to handle associated documents on a removal.
        #
        # @example Set up cascading information
        #   Movie.cascade(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class of the document.
        #
        # @since 2.0.0.rc.1
        def cascade(metadata)
          cascades.push(metadata.name.to_s) if metadata.dependent?
          self
        end
      end
    end
  end
end
