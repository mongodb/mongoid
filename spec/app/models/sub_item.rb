# frozen_string_literal: true
# encoding: utf-8

class SubItem < Item
  embedded_in :parent
end
