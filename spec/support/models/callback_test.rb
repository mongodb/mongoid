# frozen_string_literal: true
# rubocop:todo all

class CallbackTest
  include Mongoid::Document
  around_save :execute

  def execute
    yield(self)
    true
  end
end
