# frozen_string_literal: true
# rubocop:todo all

class Scheduler
  include Mongoid::Document

  def strategy
    Strategy.new
  end
end
