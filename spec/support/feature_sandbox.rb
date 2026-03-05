# frozen_string_literal: true
# rubocop:todo all

# A helper utility for allowing features to be loaded and constants defined
# inside a sandbox, where they can be unloaded and undefined when finished.
#
# @example Quarantining a block of code.
#   FeatureSandbox.quarantine do
#      require "support/rails_mock"
#      expect(defined?(Rails)).to be == "constant"
#   end
#   expect(defined?(Rails)).to be_nil
module FeatureSandbox
  extend self

  # Initiates the quarantine by noting the current state of the top-level
  # constants, the $LOADED_FEATURES array, and the $LOAD_PATH.
  #
  # @return Hash The current state of the environment.
  def start_quarantine
    { constants: Object.constants.dup,
      features: $LOADED_FEATURES.dup,
      load_path: $LOAD_PATH.dup }
  end

  # Terminates the quarantine indicated by the given state, by rolling back
  # changes made since the state was created.
  #
  # @param [ Hash ] state The state object to roll the environment back to.
  def end_quarantine(state)
    restore_load_path(state[:load_path])
    unload_features($LOADED_FEATURES - state[:features])
    unload_constants(Object, Object.constants - state[:constants])
  end

  # A convenience method for starting a quarantine, yielding to a block, and
  # then ending the quarantine when the block finishes.
  #
  # @yield The block will be executed within the quarantine, with all changes
  #    to state rolled back upon completion.
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
