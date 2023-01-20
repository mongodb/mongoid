class FeatureSandbox
  class <<self
    def start_quarantine
      { constants: Object.constants.dup,
        features: $LOADED_FEATURES.dup,
        load_path: $LOAD_PATH.dup }
    end

    def end_quarantine(state)
      restore_load_path(state[:load_path])
      unload_features($LOADED_FEATURES - state[:features])
      unload_constants(Object, Object.constants - state[:constants])
    end

    def quarantine
      state = start_quarantine
      yield
    ensure
      end_quarantine(state)
    end

    private

    def restore_load_path(list)
      $LOAD_PATH.replace(list)
    end

    def unload_features(list)
      list.each do |path|
        $LOADED_FEATURES.delete(path)
      end
    end

    def unload_constants(parent, list)
      list.each do |name|
        obj = parent.const_get(name)
        if obj.is_a?(Module) && obj.constants(false).any?
          unload_constants(obj, obj.constants(false))
        end

        Mongoid.deregister_model(obj) if obj.is_a?(Mongoid::Document)

        parent.send(:remove_const, name)
      end
    end
  end
end
