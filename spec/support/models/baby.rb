# frozen_string_literal: true
# encoding: utf-8

class Baby
  include Mongoid::Document
  embedded_in :kangaroo
end
