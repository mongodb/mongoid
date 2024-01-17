# frozen_string_literal: true
# rubocop:todo all

class SubItem < Item
  embedded_in :parent
end
