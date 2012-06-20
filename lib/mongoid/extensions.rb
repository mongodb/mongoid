# encoding: utf-8
unless defined?(Boolean)
  class Boolean; end
end

class Moped::BSON::ObjectId
  undef :as_json
  def as_json(options = nil)
    to_s
  end
  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end

class Symbol
  remove_method :size if instance_methods.include? :size # temporal fix for ruby 1.9
end

require "mongoid/extensions/array"
require "mongoid/extensions/big_decimal"
require "mongoid/extensions/boolean"
require "mongoid/extensions/date"
require "mongoid/extensions/date_time"
require "mongoid/extensions/false_class"
require "mongoid/extensions/float"
require "mongoid/extensions/hash"
require "mongoid/extensions/integer"
require "mongoid/extensions/module"
require "mongoid/extensions/nil_class"
require "mongoid/extensions/object"
require "mongoid/extensions/object_id"
require "mongoid/extensions/range"
require "mongoid/extensions/regexp"
require "mongoid/extensions/set"
require "mongoid/extensions/string"
require "mongoid/extensions/symbol"
require "mongoid/extensions/time"
require "mongoid/extensions/time_with_zone"
require "mongoid/extensions/true_class"
