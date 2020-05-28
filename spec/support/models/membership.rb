# frozen_string_literal: true
# encoding: utf-8

class Membership
  include Mongoid::Document
  embedded_in :account
end
