# encoding: utf-8
require "mongoid/extensions/time_conversions"
require "mongoid/extensions/array/accessors"
require "mongoid/extensions/array/aliasing"
require "mongoid/extensions/array/assimilation"
require "mongoid/extensions/array/conversions"
require "mongoid/extensions/array/parentization"
require "mongoid/extensions/set/conversions"
require "mongoid/extensions/big_decimal/conversions"
require "mongoid/extensions/binary/conversions"
require "mongoid/extensions/boolean/conversions"
require "mongoid/extensions/date/conversions"
require "mongoid/extensions/datetime/conversions"
require "mongoid/extensions/false_class/equality"
require "mongoid/extensions/float/conversions"
require "mongoid/extensions/hash/accessors"
require "mongoid/extensions/hash/assimilation"
require "mongoid/extensions/hash/conversions"
require "mongoid/extensions/hash/criteria_helpers"
require "mongoid/extensions/hash/scoping"
require "mongoid/extensions/integer/conversions"
require "mongoid/extensions/nil/assimilation"
require "mongoid/extensions/object/conversions"
require "mongoid/extensions/proc/scoping"
require "mongoid/extensions/string/conversions"
require "mongoid/extensions/string/inflections"
require "mongoid/extensions/symbol/inflections"
require "mongoid/extensions/true_class/equality"
require "mongoid/extensions/objectid/conversions"

class Array #:nodoc
  include Mongoid::Extensions::Array::Accessors
  include Mongoid::Extensions::Array::Assimilation
  include Mongoid::Extensions::Array::Conversions
  include Mongoid::Extensions::Array::Parentization
end

class Set #:nodoc
  include Mongoid::Extensions::Set::Conversions
end

class BigDecimal #:nodoc
  extend Mongoid::Extensions::BigDecimal::Conversions
end

class Binary #:nodoc
  extend Mongoid::Extensions::Binary::Conversions
end

class Boolean #:nodoc
  include Mongoid::Extensions::Boolean::Conversions
end

class DateTime #:nodoc
  extend Mongoid::Extensions::TimeConversions
  extend Mongoid::Extensions::DateTime::Conversions
end

class Date #:nodoc
  extend Mongoid::Extensions::TimeConversions
  extend Mongoid::Extensions::Date::Conversions
end

class FalseClass #:nodoc
  include Mongoid::Extensions::FalseClass::Equality
end

class Float #:nodoc
  extend Mongoid::Extensions::Float::Conversions
end

class Hash #:nodoc
  include Mongoid::Extensions::Hash::Accessors
  include Mongoid::Extensions::Hash::Assimilation
  include Mongoid::Extensions::Hash::CriteriaHelpers
  include Mongoid::Extensions::Hash::Scoping
  include Mongoid::Extensions::Hash::Conversions
end

class Integer #:nodoc
  extend Mongoid::Extensions::Integer::Conversions
end

class NilClass #:nodoc
  include Mongoid::Extensions::Nil::Assimilation
end

class Object #:nodoc:
  include Mongoid::Extensions::Object::Conversions
end

class Proc #:nodoc:
  include Mongoid::Extensions::Proc::Scoping
end

class String #:nodoc
  include Mongoid::Extensions::String::Inflections
  extend Mongoid::Extensions::String::Conversions
end

class Symbol #:nodoc
  remove_method :size if instance_methods.include? :size # temporal fix for ruby 1.9
  include Mongoid::Extensions::Symbol::Inflections
end

class Time #:nodoc
  extend Mongoid::Extensions::TimeConversions
end

class TrueClass #:nodoc
  include Mongoid::Extensions::TrueClass::Equality
end

class BSON::ObjectID #:nodoc
  extend Mongoid::Extensions::ObjectID::Conversions
end
