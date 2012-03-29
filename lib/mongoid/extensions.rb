# encoding: utf-8
class Binary; end #:nodoc:

unless defined?(Boolean)
  class Boolean; end
end

class BSON::ObjectId #:nodoc
  undef :as_json
  def as_json(options = nil)
    to_s
  end
  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end

class Symbol #:nodoc
  remove_method :size if instance_methods.include? :size # temporal fix for ruby 1.9
end

require "mongoid/extensions/array"
require "mongoid/extensions/false_class"
require "mongoid/extensions/hash"
require "mongoid/extensions/integer"
require "mongoid/extensions/nil_class"
require "mongoid/extensions/object"
require "mongoid/extensions/string"
require "mongoid/extensions/symbol"
require "mongoid/extensions/true_class"
require "mongoid/extensions/object_id"
