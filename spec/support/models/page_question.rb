# frozen_string_literal: true
# encoding: utf-8

class PageQuestion
  include Mongoid::Document
  embedded_in :page
end
