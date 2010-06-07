# encoding: utf-8
module Mongoid #:nodoc
  module Hierarchy #:nodoc
    extend ActiveSupport::Concern

    module InstanceMethods #:nodoc:

      # Get all child +Documents+ to this +Document+, going n levels deep if
      # necessary. This is used when calling update persistence operations from
      # the root document, where changes in the entire tree need to be
      # determined. Note that persistence from the embedded documents will
      # always be preferred, since they are optimized calls... This operation
      # can get expensive in domains with large hierarchies.
      #
      # Example:
      #
      # <tt>person._children</tt>
      #
      # Returns:
      #
      # All child +Documents+ to this +Document+ in the entire hierarchy.
      def _children
        associations.inject([]) do |children, (name, metadata)|
          if metadata.embedded?
            child = send(name)
            child.to_a.each do |doc|
              children.push(doc).concat(doc._children)
            end unless child.blank?
          end
          children
        end
      end
    end
  end
end
