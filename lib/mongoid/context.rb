module Mongoid
  class Context

    def initialize(object, options = {})
      @collection = object.collection
      @options = options
    end

    def collection(other_object = nil)
      # todo: apply options to collection
      other_object ? other_object.collection : @collection
    end
  end
end