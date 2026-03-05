# frozen_string_literal: true
# rubocop:todo all

class DelegatingPatient
  include Mongoid::Document

  embeds_one :email

  # Instance level delegation
  delegate :address, to: :email

  class << self
    # Class level delegation
    delegate :default_client, to: ::Mongoid
  end
end
