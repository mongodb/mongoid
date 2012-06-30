# encoding: utf-8
module Mongoid
  module Errors

    class NoMetadata < MongoidError

      def initialize(klass)
        super(compose_message("no_metadata", { klass: klass }))
      end
    end
  end
end
