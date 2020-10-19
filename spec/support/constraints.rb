# frozen_string_literal: true
# encoding: utf-8

module Constraints
  RAILS_VERSION = ActiveSupport.version.to_s.split('.')[0..1].join('.').freeze

  def require_driver_query_cache
    before(:all) do
      if !defined?(Mongo::QueryCache)
        skip "Driver version #{Mongo::VERSION} does not support query cache"
      end
    end
  end

  def require_mongoid_query_cache
    before (:all) do
      if defined?(Mongo::QueryCache)
        skip "Mongoid uses the driver query cache in driver versions that support it"
      end
    end
  end

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
