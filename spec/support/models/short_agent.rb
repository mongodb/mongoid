# frozen_string_literal: true

class ShortAgent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short
end
