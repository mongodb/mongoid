# frozen_string_literal: true
# encoding: utf-8

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
