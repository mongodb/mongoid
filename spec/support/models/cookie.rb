# frozen_string_literal: true

class Cookie
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  belongs_to :jar
end
