# frozen_string_literal: true
# encoding: utf-8

module Constraints
  RAILS_VERSION = ActiveSupport.version.to_s.split('.')[0..1].join('.').freeze

  def min_rails_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version > RAILS_VERSION
        skip "Rails version #{version} or higher required, we have #{RAILS_VERSION}"
      end
    end
  end

  def max_rails_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version < RAILS_VERSION
        skip "Rails version #{version} or lower required, we have #{RAILS_VERSION}"
      end
    end
  end
end
