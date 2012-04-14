# encoding: utf-8
module Mongoid
  module Relations

    # This module contains the behaviour for handling polymorphic relational
    # associations.
    module Polymorphic
      extend ActiveSupport::Concern

      included do
        class_attribute :polymorphic
      end

      module ClassMethods

        # Attempts to set up the information needed to handle a polymorphic
        # relation, if the metadata checks out.
        #
        # @example Set up the polymorphic information.
        #   Movie.polymorph(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The class being set up.
        #
        # @since 2.0.0.rc.1
        def polymorph(metadata)
          if metadata.polymorphic?
            self.polymorphic = true
            if metadata.relation.stores_foreign_key?
              field(metadata.inverse_type, type: String)
              field(metadata.inverse_of_field, type: Symbol)
            end
          end
          self
        end
      end
    end
  end
end
