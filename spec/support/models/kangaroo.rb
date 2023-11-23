# frozen_string_literal: true
# rubocop:todo all

class Kangaroo
  include Mongoid::Document
  embeds_one :baby
end
