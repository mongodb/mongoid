# frozen_string_literal: true
# rubocop:todo all

class Home
  include Mongoid::Document
  belongs_to :person
end
