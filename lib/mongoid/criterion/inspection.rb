# encoding: utf-8
module Mongoid
  module Criterion
    module Inspection

      # Get a pretty string representation of the criteria, including the
      # selector, options, matching count and documents for inspection.
      #
      # @example Inspect the criteria.
      #   criteria.inspect
      #
      # @return [ String ] The inspection string.
      #
      # @since 1.0.0
      def inspect
        ::I18n.translate(
          "mongoid.inspection.criteria",
          {
            selector: selector.inspect,
            options: options.inspect,
            klass: klass,
            embedded: embedded?
          }
        )
      end
    end
  end
end
