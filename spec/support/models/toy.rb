# frozen_string_literal: true
# encoding: utf-8

class Toy
  include Mongoid::Document
  include Mongoid::Timestamps::Short

  embedded_in :toyable, polymorphic: true

  field :type
end
