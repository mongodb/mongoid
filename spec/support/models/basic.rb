# frozen_string_literal: true
# rubocop:todo all

class Basic
  include Mongoid::Document
end

class SubBasic < Basic
end
