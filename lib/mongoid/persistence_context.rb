module Mongoid
  class PersistenceContext
    extend Forwardable

    def_delegators :client, :cluster

    def initialize(object, options = {})
      @object = object
      @options = options.dup || {}
      @collection = @options.delete(:collection)
      @client_name = @options.delete(:client)
    end

    def collection(parent = nil)
      name = parent ? parent.collection_name : collection_name
      client[name.to_sym]
    end

    def collection_name
      __evaluate__(@collection || storage_options[:collection])
    end

    def client
      @client ||= (client = Clients.with_name(client_name)
      client = client.use(database_name) if database_name
      client.with(options))
    end

    def client_name
      @client_name || Threaded.client_override || storage_options && storage_options[:client]
    end

    def database_name
      # @todo: take db in uri into account
      options[:database] || Threaded.database_override || storage_options && storage_options[:database]
    end

    def __evaluate__(name)
      return nil unless name
      name.respond_to?(:call) ? name.call.to_sym : name.to_sym
    end

    def options
      @opts ||= @options.each.reduce({}) do |opts, (key, value)|
        unless Mongo::Client::VALID_OPTIONS.include?(key.to_sym)
          raise Errors::InvalidPersistenceOption.new(key.to_sym, Mongo::Client::VALID_OPTIONS + [:client, :collection])
        end
        value ? opts.merge!(key => value) : opts
      end
    end

    def storage_options
      @object.storage_options
    end

    def ==(other)
      return false unless other.is_a?(PersistenceContext)
      options == other.options
    end

    class << self

      def get(object)
        Thread.current["[mongoid][#{object.object_id}]:context"]
      end

      def set(object, options)
        Thread.current["[mongoid][#{object.object_id}]:context"] = PersistenceContext.new(object, options)
      end

      def clear(object, cluster = nil)
        if context = get(object)
          context.client.close unless context.cluster.equal?(cluster)
        end
        Thread.current["[mongoid][#{object.object_id}]:context"] = nil
      end
    end
  end
end