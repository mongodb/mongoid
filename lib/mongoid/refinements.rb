# encoding: utf-8

module Mongoid
  class Boolean
  end
end

class BSON::ObjectId

  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end

require 'mongoid/refinements/extension'
