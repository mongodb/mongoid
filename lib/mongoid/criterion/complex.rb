# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    # Complex criterion are used when performing operations on symbols to get
    # get a shorthand syntax for where clauses.
    #
    # Example:
    #
    # <tt>{ :field => { "$lt" => "value" } }</tt>
    # becomes:
    # <tt> { :field.lt => "value }</tt>
    class Complex
      attr_accessor :key, :operator

      # Create the new complex criterion.
      def initialize(opts = {})
        @key, @operator = opts[:key], opts[:operator]
      end

      def hash
        [@key, @operator].hash
      end

      def eql?(other)
        self == (other)
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        self.key == other.key && self.operator == other.operator
      end
    end
  end
end
