# frozen_string_literal: true
# encoding: utf-8

module TouchableSpec
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
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :building, touch: true
    end
  end
end
