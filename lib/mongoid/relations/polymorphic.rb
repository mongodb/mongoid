# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This module contains the behaviour for handling polymorphic relational
    # associations.
    module Polymorphic
      extend ActiveSupport::Concern

      included do
        class_attribute :polymorphic
      end

      module ClassMethods #:nodoc:

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
          tap do |klass|
            if metadata.polymorphic?
              klass.polymorphic = true
              if metadata.relation.stores_foreign_key?
                field(metadata.inverse_type, :type => String)
              end
            end
          end
        end
      end
    end
  end
end
