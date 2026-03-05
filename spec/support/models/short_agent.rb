# frozen_string_literal: true
# rubocop:todo all

class ShortAgent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short
end
