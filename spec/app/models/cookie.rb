# frozen_string_literal: true
# encoding: utf-8

class Cookie
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  belongs_to :jar
end
