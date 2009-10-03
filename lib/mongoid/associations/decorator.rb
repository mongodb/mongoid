module Mongoid #:nodoc:
  module Associations #:nodoc:
    module Decorator #:nodoc:
      def self.included(base)
        base.class_eval do
          attr_reader :document

          # Grabs all the public methods on the document and adds them
          # to the association class. This is preferred over method_missing
          # since we can ask the class for its methods and get an
          # accurate list.
          def decorate!
            document.public_methods(false).each do |method|
              (class << self; self; end).class_eval do
                define_method method do |*args|
                  document.send method, *args
                end
              end
            end
          end
        end
      end
    end
  end
end
