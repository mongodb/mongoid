# encoding: utf-8
module Mongoid
  class Criteria
    module Marshalable

      # Provides the data needed to Marshal.dump a criteria.
      #
      # @example Dump the criteria.
      #   Marshal.dump(criteria)
      #
      # @return [ Array<Object> ] The dumped data.
      #
      # @since 3.0.15
      def marshal_dump
        data = [ klass, driver, inclusions, documents, strategy, negating ]
        data.push(scoping_options).push(dump_hash(:selector)).push(dump_hash(:options))
      end

      # Resets the criteria object after a Marshal.load
      #
      # @example Load the criteria.
      #   Marshal.load(criteria)
      #
      # @param [ Array ] data The raw data.
      #
      # @since 3.0.15
      def marshal_load(data)
        @scoping_options, raw_selector, raw_options = data.pop(3)
        @klass, @driver, @inclusions, @documents, @strategy, @negating = data
        @selector = load_hash(Origin::Selector, raw_selector)
        @options = load_hash(Origin::Options, raw_options)
      end

      private

      def dump_hash(name)
        send(name).inject({}) do |raw, (key, value)|
          raw[key] = value
          raw
        end
      end

      def load_hash(hash_class, raw)
        hash = hash_class.new(klass.aliased_fields, klass.fields)
        hash.merge!(raw)
        hash
      end
    end
  end
end
