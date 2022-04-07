# frozen_string_literal: true

module Mongoid
  class Criteria
    module Includable
      # Wrapper class for the inclusion objects.
      class Inclusion

        # @return [ Association ] The association to include.
        attr_reader :_association

        # @return [ Association ] The association above _association in the inclusion tree,
        #   if it is a nested inclusion.
        attr_reader :_previous

        def initialize(association, previous)
          @_association = association
          @_previous = previous
        end

        # @return [ String ] The class name of the documents to include.
        def class_name
          _association.class_name
        end

        # Get the class name of documents we are getting our documents from.
        #
        # For example, if we are including:
        #
        #   post.author
        #
        # The Author is the class_name since that's the class of the documents
        # we're getting, and Post is the inverse class name, since that's the
        # class of the documents that we're including the documents _from_.
        #
        # @return [ String ] The class name.
        def inverse_class_name
          _association.inverse_class_name
        end

        # @return [ Boolean ] Is there a previous association?
        def previous?
          !!_previous
        end

        # @return [ Class ] The relation class to use for eager loading.
        def relation
          _association.relation
        end

        # @return [ String ] The association name.
        def name
          _association.name
        end

        def ==(other)
          other.is_a?(Inclusion) &&
            _association == other._association &&
            _previous == other._previous
        end
      end
    end
  end
end
