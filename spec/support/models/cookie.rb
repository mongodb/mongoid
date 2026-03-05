# frozen_string_literal: true
# rubocop:todo all

class Cookie
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  belongs_to :jar
end
