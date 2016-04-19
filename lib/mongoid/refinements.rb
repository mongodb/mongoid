# encoding: utf-8

unless defined?(Boolean)
  class Boolean; end
end

module Mongoid
  class Boolean; end
end

class BSON::ObjectId

  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end

require 'mongoid/refinements/array'
require 'mongoid/refinements/big_decimal'
require 'mongoid/refinements/boolean'
require 'mongoid/refinements/date'
require 'mongoid/refinements/date_time'
require 'mongoid/refinements/false_class'
require 'mongoid/refinements/float'
require 'mongoid/refinements/hash'
require 'mongoid/refinements/integer'
require 'mongoid/refinements/module'
require 'mongoid/refinements/nil_class'
require 'mongoid/refinements/object'
require 'mongoid/refinements/object_id'
require 'mongoid/refinements/range'
require 'mongoid/refinements/regexp'
require 'mongoid/refinements/set'
require 'mongoid/refinements/string'
require 'mongoid/refinements/symbol'
require 'mongoid/refinements/time'
require 'mongoid/refinements/time_with_zone'
require 'mongoid/refinements/true_class'
