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

        private

        # Parses the options and sets the polymorphic flag if the document is
        # part of a polymorphic relation.
        #
        # @example Set polymorphic depending on the options.
        #   Movie.determine_polymorphism(:as => :ratable)
        #
        # @param [ Hash ] options The options passed to the relation macro.
        def determine_polymorphism(options)
          self.polymorphic = true if options[:as] || options[:polymorphic]
        end
      end
    end
  end
end
