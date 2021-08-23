# frozen_string_literal: true

class PageQuestion
  include Mongoid::Document
  embedded_in :page
end
