# frozen_string_literal: true

class Override
  include Mongoid::Document

  def self.public_method; end

  def self.protected_method; end

  def self.private_method; end
end
