# encoding: utf-8
module Origin

  # Allows for easy delegation of origin queryable instance methods to a
  # specific method.
  module Forwardable

    # Tells origin with method on the class to delegate to when calling an
    # original selectable or optional method on the class.
    #
    # @example Tell origin where to select from.
    #   class Band
    #     extend Origin::Forwardable
    #     select_with :criteria
    #
    #     def self.criteria
    #       Query.new
    #     end
    #   end
    #
    # @param [ Symbol ] receiver The name of the receiver method.
    #
    # @return [ Array<Symbol> ] The names of the forwarded methods.
    #
    # @since 1.0.0
    def select_with(receiver)
      (Selectable.forwardables + Optional.forwardables).each do |name|
        __forward__(name, receiver)
      end
    end

    private

    # Forwards the method name to the provided receiver method.
    #
    # @api private
    #
    # @example Define the forwarding.
    #   Model.__forward__(:exists, :criteria)
    #
    # @param [ Symbol ] name The name of the method.
    # @param [ Symbol ] receiver The name of the receiver method.
    #
    # @since 1.0.0
    def __forward__(name, receiver)
      if self.class == Module
        module_eval <<-SEL
          def #{name}(*args, &block)
            #{receiver}.__send__(:#{name}, *args, &block)
          end
        SEL
      else
        (class << self; self; end).class_eval <<-SEL
          def #{name}(*args, &block)
            #{receiver}.__send__(:#{name}, *args, &block)
          end
        SEL
      end
    end
  end
end
