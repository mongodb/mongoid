module Constraints
  RAILS_VERSION = ActiveSupport.version.to_s.split('.')[0..1].join('.').freeze

  def min_rails_version(version)
    unless version =~ /^\d+\.\d+$/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before do
      if version > RAILS_VERSION
        skip "Rails version #{version} or higher required, we have #{RAILS_VERSION}"
      end
    end
  end

  def max_rails_version(version)
    unless version =~ /^\d+\.\d+$/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before do
      if version < RAILS_VERSION
        skip "Rails version #{version} or lower required, we have #{RAILS_VERSION}"
      end
    end
  end

  def min_server_version(version)
    unless version =~ /^\d+\.\d+$/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before do
      if version > ClusterConfig.instance.server_version
        skip "Server version #{version} or higher required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def max_server_version(version)
    unless version =~ /^\d+\.\d+$/
      raise ArgumentError, "Version can only be major.minor: #{version}"
    end

    before do
      if version < ClusterConfig.instance.short_server_version
        skip "Server version #{version} or lower required, we have #{ClusterConfig.instance.server_version}"
      end
    end
  end

  def require_topology(*topologies)
    topologies = topologies.map { |t| t.to_s }
    invalid_topologies = topologies - %w(single replica_set sharded)
    unless invalid_topologies.empty?
      raise ArgumentError, "Invalid topologies requested: #{invalid_topologies.join(', ')}"
    end
    before do
      topology = Mongoid.default_client.cluster.topology.class.name.sub(/.*::/, '')
      topology = topology.gsub(/([A-Z])/) { |match| '_' + match.downcase }.sub(/^_/, '')
      if topology =~ /^replica_set/
        topology = 'replica_set'
      end
      unless topologies.include?(topology)
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
    min_server_version '4.0'
    require_topology :replica_set
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
