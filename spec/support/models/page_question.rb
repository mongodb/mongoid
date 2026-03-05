# frozen_string_literal: true
# rubocop:todo all

class PageQuestion
  include Mongoid::Document
  embedded_in :page
end
