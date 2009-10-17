require "mongoid/extensions/array/conversions"
require "mongoid/extensions/array/parentization"
require "mongoid/extensions/object/conversions"
require "mongoid/extensions/object/parentization"

class Array #:nodoc:
  include Mongoid::Extensions::Array::Conversions
  include Mongoid::Extensions::Array::Parentization
end

class Object #:nodoc:
  include Mongoid::Extensions::Object::Conversions
  include Mongoid::Extensions::Object::Parentization
end