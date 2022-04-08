# frozen_string_literal: true

module Mongoid
  class Criteria
    module Includable
      # Wrapper class for the inclusion objects.
      class Inclusion
        extend Forwardable

        # @return [ Association ] The association to include.
        attr_reader :association

        # @return [ String ] The name of the association above _association in
        #   the inclusion tree, if it is a nested inclusion.
        attr_reader :parent

        # Delegate these methods to _association.
        def_delegators :association, :class_name, :inverse_class_name,
                       :relation, :name

        def initialize(association, parent = nil)
          @association = association
          @parent = parent
        end

        # @return [ Boolean ] Is there a parent inclusion?
        def parent?
          !!parent
        end

        def ==(other)
          other.is_a?(Inclusion) &&
            association == other.association &&
            parent == other.parent
        end
      end
    end
  end
end
