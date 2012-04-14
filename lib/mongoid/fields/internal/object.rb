# encoding: utf-8
module Mongoid
  module Fields
    module Internal
      # Defines the behaviour for object fields.
      class Object
        include Serializable
      end
    end
  end
end
