module Mongoid
  module Timestamps
    module Serverside
      extend ActiveSupport::Concern

      included do
        raise "Mongoid::Timestamps::Serverside should be included before any fields definition to work properly" if fields.size > 1

        field :ts, type: Moped::BSON::Timestamp
        set_callback :create, :before, :set_ts
        set_callback :save, :before, :set_ts
      end

      def set_ts
        self.ts = Moped::BSON::Timestamp.new(0, 0)
      end
    end
  end
end
