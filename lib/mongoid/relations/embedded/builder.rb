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
        # parent: The parent document, if applicable
        def initialize(metadata, attributes, parent = nil)
          @metadata, @attributes, @parent = metadata, attributes, parent
        end
      end
    end
  end
end
