# frozen_string_literal: true
# encoding: utf-8

class Scheduler
  include Mongoid::Document

  def strategy
    Strategy.new
  end
end
