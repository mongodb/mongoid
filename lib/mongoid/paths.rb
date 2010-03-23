# encoding: utf-8
module Mongoid #:nodoc:
  module Paths #:nodoc:
    extend ActiveSupport::Concern
    included do
      cattr_accessor :_path
      delegate :_path, :to => "self.class"
    end
    module InstanceMethods
      # Return the path to this +Document+ in JSON notation, used for atomic
      # updates via $set in MongoDB.
      #
      # Example:
      #
      # <tt>address.path # returns "addresses"</tt>
      def path
        self._path ||= climb("") do |document, value|
          value = "#{document.association_name}#{"." + value unless value.blank?}"
        end
      end

      # Return the selector for this document to be matched exactly for use
      # with MongoDB's $ operator.
      #
      # Example:
      #
      # <tt>address.selector</tt>
      def selector
        @selector ||= climb({ "_id" => _root.id }) do |document, value|
          value["#{document.path}._id"] = document.id; value
        end
      end

      protected
      def climb(value, &block)
        document = self;
        while (document._parent) do
          value = yield document, value
          document = document._parent
        end
        value
      end
    end
  end
end
