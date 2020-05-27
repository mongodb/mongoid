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

  def min_server_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version > ClusterConfig.instance.server_version
        skip "Server version #{version} or higher required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def max_server_version(version)
    unless version =~ /\A\d+\.\d+\z/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before(:all) do
      if version < ClusterConfig.instance.short_server_version
        skip "Server version #{version} or lower required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def require_topology(*topologies)
    invalid_topologies = topologies - [:single, :replica_set, :sharded]

    unless invalid_topologies.empty?
      raise ArgumentError, "Invalid topologies requested: #{invalid_topologies.join(', ')}"
    end

    before(:all) do
      unless topologies.include?(topology = ClusterConfig.instance.topology)
        skip "Topology #{topologies.join(' or ')} required, we have #{topology}"
      end
    end
  end

  def max_example_run_time(timeout)
    around do |example|
      TimeoutInterrupt.timeout(timeout, TimeoutInterrupt::Error.new("Test execution terminated after #{timeout} seconds")) do
        example.run
      end
    end
  end

  def require_transaction_support
    before(:all) do
      case ClusterConfig.instance.topology
      when :single
        skip 'Transactions tests require a replica set (4.0+) or a sharded cluster (4.2+)'
      when :replica_set
        unless ClusterConfig.instance.server_version >= '4.0'
          skip 'Transactions tests in a replica set topology require server 4.0+'
        end
      when :sharded
        unless ClusterConfig.instance.server_version >= '4.2'
          skip 'Transactions tests in a sharded cluster topology require server 4.2+'
        end
      else
        raise NotImplementedError
      end
    end
  end

  def require_tls
    before(:all) do
      unless SpecConfig.instance.ssl?
        skip "SSL not enabled"
      end
    end
  end

  def require_no_tls
    before(:all) do
      if SpecConfig.instance.ssl?
        skip "SSL enabled"
      end
    end
  end

  def require_local_tls
    require_tls
  end

  def require_no_retry_writes
    before(:all) do
      if SpecConfig.instance.retry_writes?
        skip "Retry writes is enabled"
      end
    end
  end

  def require_compression
    before(:all) do
      if SpecConfig.instance.compressors.nil?
        skip "Compression is not enabled"
      end
    end
  end

  def require_no_compression
    before(:all) do
      if SpecConfig.instance.compressors
        skip "Compression is enabled"
      end
    end
  end

  def ruby_version_gte(version)
    before(:all) do
      if RUBY_VERSION < version
        skip "Ruby version #{version} or higher required"
      end
    end
  end

  def ruby_version_lt(version)
    before(:all) do
      if RUBY_VERSION >= version
        skip "Ruby version less than #{version} required"
      end
    end
  end

  def require_auth
    before(:all) do
      unless ENV['AUTH'] == 'auth' || SpecConfig.instance.user || ClusterConfig.instance.auth_enabled?
        skip "Auth required"
      end
    end
  end

  def require_no_auth
    before(:all) do
      if ENV['AUTH'] == 'auth' || SpecConfig.instance.user || ClusterConfig.instance.auth_enabled?
        skip "Auth not allowed"
      end
    end
  end

  def require_no_x509_auth
    before(:all) do
      if SpecConfig.instance.x509_auth?
        skip "X.509 auth not allowed"
      end
    end
  end

  # Can the driver specify a write concern that won't be overridden?
  # (mongos 4.0+ overrides the write concern)
  def require_set_write_concern
    before(:all) do
      if ClusterConfig.instance.topology == :sharded && ClusterConfig.instance.short_server_version >= '4.0'
        skip "mongos 4.0+ overrides write concern"
      end
    end
  end

  def require_multi_shard
    before(:all) do
      if ClusterConfig.instance.topology == :sharded && SpecConfig.instance.addresses.length == 1
        skip 'Test requires a minimum of two shards if run in sharded topology'
      end
    end
  end

  def require_no_multi_shard
    before(:all) do
      if ClusterConfig.instance.topology == :sharded && SpecConfig.instance.addresses.length > 1
        skip 'Test requires a single shard if run in sharded topology'
      end
    end
  end

  def require_wired_tiger
    before(:all) do
      if ClusterConfig.instance.storage_engine != :wired_tiger
        skip 'Test requires WiredTiger storage engine'
      end
    end
  end

  def require_wired_tiger_on_36
    before(:all) do
      if ClusterConfig.instance.short_server_version >= '3.6'
        if ClusterConfig.instance.storage_engine != :wired_tiger
          skip 'Test requires WiredTiger storage engine on 3.6+ servers'
        end
      end
    end
  end

  def require_mmapv1
    before(:all) do
      if ClusterConfig.instance.storage_engine != :mmapv1
        skip 'Test requires MMAPv1 storage engine'
      end
    end
  end

  def require_enterprise
    before(:all) do
      unless ClusterConfig.instance.enterprise?
        skip 'Test requires enterprise build of MongoDB'
      end
    end
  end

  # Integration tests for SRV polling require internet connectivity to
  # look up SRV records and a sharded cluster configured on default port on
  # localhost (localhost:27017, localhost:27018).
  def require_default_port_deployment
    # Because the DNS records at test1.test.build.10gen.cc point to
    # localhost:27017 & localhost:27018, the test suite must have been
    # configured to use these addresses
    before(:all) do
      have_default_port = SpecConfig.instance.addresses.any? do |address|
        %w(127.0.0.1 127.0.0.1:27017 localhost localhost:27017).include?(address)
      end
      unless have_default_port
        skip 'This test requires the test suite to be configured for localhost:27017'
      end
    end
  end
end
