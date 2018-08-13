# frozen_string_literal: true

class Home
  include Mongoid::Document
  belongs_to :person
end
