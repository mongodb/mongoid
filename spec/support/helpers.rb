module Helpers
  # Reloads the specified model class.
  #
  # @param [ String | Symbol ] name Class name to reload.
  def reload_model(name)
    Object.class_eval do
      remove_const(name)
    end
    load "spec/support/models/#{name.to_s.underscore}.rb"
  end
end
