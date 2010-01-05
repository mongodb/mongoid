module Mongoid #:nodoc
  module Memoization

    # Handles cases when accessing an association that should be memoized in
    # the Mongoid specific manner.
    def memoized(name, &block)
      var = "@#{name}"
      if instance_variable_defined?(var)
        return instance_variable_get(var)
      end
      value = yield
      instance_variable_set(var, value)
    end

    # Mongoid specific behavior is to remove the memoized object when setting
    # the association, or if it wasn't previously memoized it will get set.
    def reset(name, &block)
      var = "@#{name}"
      value = yield
      if instance_variable_defined?(var)
        remove_instance_variable(var)
      else
        instance_variable_set(var, value)
      end
    end
  end
end
