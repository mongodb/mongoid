# frozen_string_literal: true
# rubocop:todo all

class Fish
  include Mongoid::Document

  def self.fresh
    where(fresh: true)
  end
end
