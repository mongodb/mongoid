# encoding: utf-8
class BSON::ObjectId
  def as_json(options = nil)
    { "$oid" => to_s }
  end
  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end

class Symbol
  remove_method :size if instance_methods.include? :size # temporal fix for ruby 1.9
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

