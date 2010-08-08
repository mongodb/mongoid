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
        # attributes: The attributes to build from.
        def initialize(metadata, attributes)
          @metadata, @attributes = metadata, attributes
        end
      end
    end
  end
end
