# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # This class contains metadata about association proxies.
    class MetaData

      attr_reader :association, :options

      delegate :macro, :to => :association

      # Delegate all methods on +Options+ to the options instance.
      Associations::Options.public_instance_methods(false).each do |name|
        define_method(name) { |*args| @options.send(name) }
      end

      # Return true if this meta data is for an embedded association.
      #
      # Example:
      #
      # <tt>metadata.embedded?</tt>
      def embedded?
        [ EmbedsOne, EmbedsMany ].include?(association)
      end

      # Create the new associations MetaData object, which holds the type of
      # the association and its options, with convenience methods for getting
      # that information.
      #
      # Options:
      #
      # association: The association type as a class instance.
      # options: The association options
      def initialize(association, options)
        @association, @options = association, options
      end
    end
  end
end
