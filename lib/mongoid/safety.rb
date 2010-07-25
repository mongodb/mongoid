# encoding: utf-8
module Mongoid #:nodoc:

  # The +Safety+ module is used to provide a DSL to execute database operations
  # in safe mode on a per query basis, either from the +Document+ class level
  # or instance level.
  module Safety
    extend ActiveSupport::Concern

    # Execute the following class-level persistence operation in safe mode.
    #
    # Example:
    #
    # <tt>person.safely.upsert</tt>
    # <tt>person.safely.destroy</tt>
    #
    # Returns:
    #
    # A +Proxy+ to the +Document+.
    def safely
      Proxy.new(self)
    end

    module ClassMethods #:nodoc:

      # Execute the following class-level persistence operation in safe mode.
      #
      # Example:
      #
      # <tt>Person.safely.create(:name => "John")</tt>
      # <tt>Person.safely.delete_all</tt>
      #
      # Returns:
      #
      # A +Proxy+ to the +Document+ class.
      def safely
        Proxy.new(self)
      end
    end

    # When this class proxies a document or class, the next persistence
    # operation executed on it will query in safe mode.
    class Proxy

      attr_reader :target

      # Create the new +Proxy+.
      #
      # Options:
      #
      # target: Either the class or the instance.
      def initialize(target)
        @target = target
      end
    end
  end
end
