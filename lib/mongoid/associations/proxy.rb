# encoding: utf-8
module Mongoid #:nodoc
  module Associations #:nodoc
    module Proxy #:nodoc
      extend ActiveSupport::Concern
      included do
        instance_methods.each do |method|
          undef_method(method) unless method =~ /(^__|^nil\?$|^send$|^object_id$)/
        end
      end
    end
  end
end
