# encoding: utf-8
module Mongoid

  # Contains behaviour specific to evolving for queryable queries.
  module Evolvable

    # Evolve the document into an object id.
    #
    # @example Evolve the document.
    #   document.evolve_object_id
    #
    # @return [ Object ] The document's id.
    #
    # @since 3.0.0
    def evolve_object_id
      id
    end
  end
end
