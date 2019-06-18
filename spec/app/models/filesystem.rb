# frozen_string_literal: true
# encoding: utf-8

class Filesystem
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  embedded_in :server
end
