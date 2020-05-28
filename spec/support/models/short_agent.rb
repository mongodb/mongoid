# frozen_string_literal: true
# encoding: utf-8

class ShortAgent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short
end
