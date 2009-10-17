require "mongoid/extensions/array/conversions"
require "mongoid/extensions/array/parentization"
require "mongoid/extensions/object/conversions"

class Array #:nodoc:
  include Mongoid::Extensions::Array::Conversions
  include Mongoid::Extensions::Array::Parentization
end

class Object #:nodoc:
  include Mongoid::Extensions::Object::Conversions
end