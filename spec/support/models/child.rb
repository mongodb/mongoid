# frozen_string_literal: true
# rubocop:todo all

class Child
  include Mongoid::Document
  embedded_in :parent, inverse_of: :childable, polymorphic: true
end
