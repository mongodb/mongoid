# frozen_string_literal: true
# encoding: utf-8

class CallbackTest
  include Mongoid::Document
  around_save :execute

  def execute
    yield(self)
    true
  end
end
