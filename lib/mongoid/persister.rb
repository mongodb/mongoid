module Mongoid
  class Persister
    include ActiveSupport::Callbacks

    define_callbacks \
      :after_create,
      :after_save,
      :before_create,
      :before_save

    def initialize(document)
      @document = document
    end

    def create
      run_callbacks(:before_create)
    end

  end
end
