# frozen_string_literal: true
# encoding: utf-8

class Sound
  include Mongoid::Document
  field :active, type: Mongoid::Boolean
  default_scope ->{ where(active: true) }
end
