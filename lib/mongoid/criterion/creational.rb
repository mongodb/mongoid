# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # This module defines criteria behavior for creating documents in the
    # database for specified conditions.
    module Creational

      # Create a document in the database given the selector and return it.
      # Complex criteria, such as $in and $or operations will get ignored.
      #
      # @example Create the document.
      #   Person.where(:title => "Sir").create
      def create
        klass.create(
          selector.inject({}) do |hash, (key, value)|
            hash.tap do |attrs|
              unless key.to_s =~ /\$/ || value.is_a?(Hash)
                attrs[key] = value
              end
            end
          end
        )
      end
    end
  end
end
