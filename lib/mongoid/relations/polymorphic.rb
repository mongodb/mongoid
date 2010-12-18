# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Polymorphic #:nodoc:
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :polymorphic

        delegate :polymorphic?, :to => "self.class"
      end

      module ClassMethods #:nodoc:

        # Attempts to set up the information needed to handle a polymorphic
        # relation, if the metadata checks out.
        #
        # @example Set up the polymorphic information.
        #   Movie.polymorph(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        def polymorph(metadata)
          if metadata.polymorphic?
            self.polymorphic = true
            if metadata.relation.stores_foreign_key?
              field(metadata.inverse_type, :type => String)
            end
          end
        end

        # Determines if the class is in a polymorphic relations, and thus must
        # store the _type field in the database.
        #
        # @example Check if the class is polymorphic.
        #   Movie.polymorphic?
        #
        # @return [ Boolean ] True if polymorphic, false if not.
        def polymorphic?
          !!polymorphic
        end
      end
    end
  end
end
