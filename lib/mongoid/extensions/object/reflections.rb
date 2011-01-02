# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      module Reflections #:nodoc:
        extend ActiveSupport::Concern

        def ivar(name)
          if instance_variable_defined?("@#{name}")
            return instance_variable_get("@#{name}")
          end
          nil
        end
      end
    end
  end
end
