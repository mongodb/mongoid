# frozen_string_literal: true
# encoding: utf-8
module Mongoid
  class Criteria
    module Queryable

      # Allows for easy delegation of queryable queryable instance methods to a
      # specific method.
      module Forwardable

        # Tells queryable with method on the class to delegate to when calling an
        # original selectable or optional method on the class.
        #
        # @example Tell queryable where to select from.
        #   class Band
        #     extend Queryable::Forwardable
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
            module_eval <<-SEL, __FILE__, __LINE__ + 1
              def #{name}(*args, &block)
                #{receiver}.__send__(:#{name}, *args, &block)
              end
            SEL
          else
            singleton_class.class_eval <<-SEL, __FILE__, __LINE__ + 1
              def #{name}(*args, &block)
                #{receiver}.__send__(:#{name}, *args, &block)
              end
            SEL
          end
        end
      end
    end
  end
end
