module Mongoid
  class PersistenceContext
    extend Forwardable

    def_delegators :client, :cluster

    attr_reader :options

    EXTRA_OPTIONS = [ :client,
                      :collection
                    ].freeze

    VALID_OPTIONS = (Mongo::Client::VALID_OPTIONS + EXTRA_OPTIONS).freeze

    def initialize(object, opts = {})
      @object = object
      set_options!(opts)
    end

    def collection(parent = nil)
      @collection ||= (name = parent ? parent.collection_name : collection_name
      client[name.to_sym])
    end

    def collection_name
      @collection_name ||= (__evaluate__(options[:collection] ||
                              storage_options[:collection]))
    end

    def client
      @client ||= (client = Clients.with_name(client_name)
      client = client.use(database_name) if database_name_option
      client.with(client_options))
    end

    def ==(other)
      return false unless other.is_a?(PersistenceContext)
      options == other.options
    end

    def database_name
      database_name_option || client.database.name
    end

    private

    def client_name
      @client_name ||= (options[:client] ||
          Threaded.client_override ||
          storage_options && storage_options[:client])
    end

    def set_options!(opts)
      @options ||= opts.each.reduce({}) do |_options, (key, value)|
        unless VALID_OPTIONS.include?(key.to_sym)
          raise Errors::InvalidPersistenceOption.new(key.to_sym, VALID_OPTIONS)
        end
        value ? _options.merge!(key => value) : _options
      end
    end

    def __evaluate__(name)
      return nil unless name
      name.respond_to?(:call) ? name.call.to_sym : name.to_sym
    end

    def client_options
      @client_options ||= options.select { |k, v| Mongo::Client::VALID_OPTIONS.include?(k.to_sym) }
    end

    def storage_options
      @object.storage_options
    end

    def database_name_option
      @database_name_option ||= options[:database] ||
          Threaded.database_override ||
          storage_options && storage_options[:database]
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