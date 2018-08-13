# frozen_string_literal: true

class Kangaroo
  include Mongoid::Document
  embeds_one :baby
end
