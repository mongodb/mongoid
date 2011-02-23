# encoding: utf-8
module Mongoid #:nodoc
  module Sharding #:nodoc
    extend ActiveSupport::Concern
    included do
      cattr_accessor :shard_key_fields
      self.shard_key_fields = []
    end

    module ClassMethods #:nodoc
      # Specifies a shard key with the field(s) specified.
      def shard_key(*names)
        self.shard_key_fields = names
      end
    end
    
    def shard_key_selector
      selector = {}
      self.class.shard_key_fields.each do |field|
        selector[field.to_s] = self.send(field)
      end
      selector
    end
  end
end