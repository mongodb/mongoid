# frozen_string_literal: true

module Mongoid
  module Extensions

    # A factory for manufacturing Mongoid::<Type>Array classes.
    module TypedArrayClassFactory

      class << self

        # Create or retrieve the typed array class. If the class has not already
        # been created, create a class called {Type}Array that inherits from
        # Mongoid::TypedArray.
        #
        # @param [ Class ] type The type of the field.
        #
        # @return [ Class ] The typed array class.
        #
        # @api private
        def create(type)
          LOCK.synchronize do
            const_string = "#{type}Array"
            if Mongoid.const_defined?(const_string)
              Mongoid.const_get(const_string)
            else
              array_class = typed_array_class(type)
              array_class.const_set("Type", type)
              Mongoid.const_set(const_string, array_class)
            end
          end
        end

        private

        # @api private
        LOCK = Mutex.new

        # Create the typed array class.
        #
        # @param [ Class ] type The type of the field.
        #
        # @return [ Class ] The typed array class.
        #
        # @api private
        def typed_array_class(type)
          Class.new(Mongoid::TypedArray) do
            def initialize(*args, &block)
              super(self.class.const_get("Type"), *args, &block)
            end

            class << self
              def mongoize(object)
                return if object.nil?
                case object
                when Array, Set
                  object.map { |x| const_get("Type").mongoize(x) }
                end
              end

              def demongoize(object)
                return if object.nil?
                case object
                when self then object
                when Array, Set
                  new(object.to_a)
                end
              end

              def evolve(object)
                case object
                when Array, Set
                  object.map { |x| const_get("Type").evolve(x) }
                else
                  object
                end
              end
            end
          end
        end
      end
    end
  end
end
