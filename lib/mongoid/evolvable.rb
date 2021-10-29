# frozen_string_literal: true

module Mongoid

  # Contains behavior specific to evolving for queryable queries.
  module Evolvable

    # Evolve the document into an object id.
    #
    # @example Evolve the document.
    #   document.__evolve_object_id__
    #
    # @return [ Object ] The document's id.
    def __evolve_object_id__
      _id
    end
  end
end
