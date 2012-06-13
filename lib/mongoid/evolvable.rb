# encoding: utf-8
module Mongoid

  # Contains behaviour specific to evolving for origin queries.
  module Evolvable

    # Evolve the document into an object id.
    #
    # @example Evolve the document.
    #   document.__evolve_object_id__
    #
    # @return [ Object ] The document's id.
    #
    # @since 3.0.0
    def __evolve_object_id__
      id
    end
  end
end
