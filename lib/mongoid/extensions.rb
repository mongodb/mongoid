# frozen_string_literal: true
# encoding: utf-8

class BSON::ObjectId
  def as_json(options = nil)
    { "$oid" => to_s }
  end
end

class BSON::Document
  # We need to override this as ActiveSupport creates a new Object, instead of a new Hash
  # see https://github.com/rails/rails/commit/f1bad130d0c9bd77c94e43b696adca56c46a66aa
  def transform_keys
    return enum_for(:transform_keys) unless block_given?
    result = {}
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end
end

require "mongoid/extensions/array"
require "mongoid/extensions/big_decimal"
require "mongoid/extensions/boolean"
require "mongoid/extensions/date"
require "mongoid/extensions/date_time"
require "mongoid/extensions/decimal128"
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
