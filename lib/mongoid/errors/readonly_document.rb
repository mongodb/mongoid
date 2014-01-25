# encoding: utf-8
module Mongoid
  module Errors

    class ReadonlyDocument < MongoidError

      def initialize(klass)
        super(compose_message("readonly_document", { klass: klass }))
      end
    end
  end
end
