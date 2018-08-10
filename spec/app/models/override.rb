# frozen_string_literal: true

class Override
  include Mongoid::Document

  def self.public_method
  end

  protected

  def self.protected_method
  end

  private

  def self.private_method
  end
end
