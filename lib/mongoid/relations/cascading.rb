# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cascading #:nodoc:
      extend ActiveSupport::Concern

      included do
        class_inheritable_accessor :cascades
        self.cascades = {}
      end

      module ClassMethods #:nodoc:

        # Attempt to add the cascading information for the document to know how
        # to handle associated documents on a removal.
        #
        # @example Set up cascading information
        #   Movie.cascade(metadata)
        #
        # @param [ Metadata ] metadata The metadata for the relation.
        #
        # @return [ Class ] The class of the document.
        def cascade(metadata)
          tap do
            if metadata.dependent?
              cascades[metadata.name.to_s] = metadata.dependent
            end
          end
        end
      end
    end
  end
end
