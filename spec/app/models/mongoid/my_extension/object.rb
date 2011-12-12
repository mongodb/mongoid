module Mongoid
  module MyExtension
    class Object
      include Mongoid::Fields::Serializable
    end
  end
end
