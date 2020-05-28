# frozen_string_literal: true
# encoding: utf-8

class Fish
  include Mongoid::Document

  def self.fresh
    where(fresh: true)
  end
end
