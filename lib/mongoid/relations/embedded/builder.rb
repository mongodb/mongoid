# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:
      class Builder #:nodoc:

        # Instantiate the new builder for embeds one relation.
        #
        # Options:
        #
        # metadata: The metadata for the relation.
        # object: The attributes or document to build from.
        # parent: The parent document, if applicable
        def initialize(metadata, object, parent = nil)
          @metadata, @object, @parent = metadata, object, parent
        end
      end
    end
  end
end
