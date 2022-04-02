# frozen_string_literal: true

module TouchableSpec
  class NoTimestamps
    include Mongoid::Document

    field :last_used_at, as: :aliased_field, type: Time
  end

  class NoAssociations
    include Mongoid::Document
    include Mongoid::Timestamps

    field :last_used_at, as: :aliased_field, type: Time
  end

  module Embedded
    class Building
      include Mongoid::Document
      include Mongoid::Timestamps

      embeds_many :entrances
      embeds_many :floors
    end

    class Entrance
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :building

      field :last_used_at, type: Time
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :building, touch: true

      field :last_used_at, type: Time
    end
  end

  module Referenced
    class Building
      include Mongoid::Document
      include Mongoid::Timestamps

      has_many :entrances, inverse_of: :building
      has_many :floors, inverse_of: :building
    end

    class Entrance
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :building

      field :last_used_at, type: Time
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :building, touch: true

      field :last_used_at, type: Time
    end
  end
end
