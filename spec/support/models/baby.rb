# frozen_string_literal: true
# rubocop:todo all

class Baby
  include Mongoid::Document
  embedded_in :kangaroo
end
