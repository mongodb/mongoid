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
        def initialize(metadata, object)
          @metadata, @object = metadata, object
        end
      end
    end
  end
end
