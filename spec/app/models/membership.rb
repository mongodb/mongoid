# frozen_string_literal: true

class Membership
  include Mongoid::Document
  embedded_in :account
end
