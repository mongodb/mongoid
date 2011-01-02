# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    module Ids
      # Return documents based on an id search. Will handle if a single id has
      # been passed or mulitple ids.
      #
      # Example:
      #
      #   context.id_criteria([1, 2, 3])
      #
      # Returns:
      #
      # The single or multiple documents.
      def id_criteria(params)
        self.criteria = criteria.id(params)
        result = params.is_a?(Array) ? criteria.entries : one
        if Mongoid.raise_not_found_error && !params.blank?
          raise Errors::DocumentNotFound.new(klass, params) if result.blank?
        end
        return result
      end
    end
  end
end
