module Custom
  class Type
    include Mongoid::Fields::Serializable
  end

  class String
    include Mongoid::Fields::Serializable
  end
end

module Mongoid
  module MyExtension
    class Object
      include Mongoid::Fields::Serializable
    end
  end
end