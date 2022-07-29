# frozen_string_literal: true

module Constraints
  RAILS_VERSION = ActiveSupport.version.to_s.split('.')[0..1].join('.').freeze

  def min_driver_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = driver_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) < 0
        skip "Driver version #{version} or higher is required"
      end
    end
  end

  def max_driver_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = driver_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) > 0
        skip "Driver version #{version} or lower is required"
      end
    end
  end

  def driver_version(precision)
    Mongo::VERSION.split('.')[0...precision].map(&:to_i)
  end

  def min_bson_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = bson_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) < 0
        skip "bson-ruby version #{version} or higher is required"
      end
    end
  end

  def max_bson_version(version)
    required_version = version.split('.').map(&:to_i)
    actual_version = bson_version(required_version.length)
    before(:all) do
      if (actual_version <=> required_version) > 0
        skip "bson-ruby version #{version} or lower is required"
      end
    end
  end

  def bson_version(precision)
    BSON::VERSION.split('.')[0...precision].map(&:to_i)
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
