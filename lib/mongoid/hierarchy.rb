# encoding: utf-8
module Mongoid #:nodoc
  module Hierarchy #:nodoc
    extend ActiveSupport::Concern

    module InstanceMethods #:nodoc:

      # Get all child +Documents+ to this +Document+, going n levels deep if
      # necessary.
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
            children.concat(child.to_a) unless child.blank?
          end
          children
        end
      end
    end
  end
end
