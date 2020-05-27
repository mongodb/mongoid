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
      TimeoutInterrupt.timeout(timeout) do
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

  def require_scram_sha_256_support
    before do
      $mongo_server_features ||= begin
        scanned_client_server!.features
      end
      unless $mongo_server_features.scram_sha_256_enabled?
        skip "SCRAM SHA 256 is not enabled on the server"
      end
    end
  end

  def require_ssl
    before do
      unless SpecConfig.instance.ssl?
        skip "SSL not enabled"
      end
    end
  end
end
