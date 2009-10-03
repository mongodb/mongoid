require "mongoid/extensions/array/conversions"
require "mongoid/extensions/object/conversions"

class Array #:nodoc:
  include Mongoid::Extensions::Array::Conversions
end

class Object #:nodoc:
  include Mongoid::Extensions::Object::Conversions
end