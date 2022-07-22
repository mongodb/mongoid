# frozen_string_literal: true

module TouchableSpec
  module Embedded
    class Building
      include Mongoid::Document
      include Mongoid::Timestamps

      field :title, type: String

      embeds_many :entrances, class_name: "TouchableSpec::Embedded::Entrance"
      embeds_many :floors, class_name: "TouchableSpec::Embedded::Floor"
    end

    class Entrance
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :building, touch: false, class_name: "TouchableSpec::Embedded::Building"

      field :last_used_at, type: Time
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :level, type: Integer

      embedded_in :building, touch: true, class_name: "TouchableSpec::Embedded::Building"
    end
  end

  module Referenced
    class Building
      include Mongoid::Document
      include Mongoid::Timestamps

      has_many :entrances, inverse_of: :building, class_name: "TouchableSpec::Referenced::Entrance"
      has_many :floors, inverse_of: :building, class_name: "TouchableSpec::Referenced::Floor"
    end

    class Entrance
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :building, touch: false, class_name: "TouchableSpec::Referenced::Building"
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :level, type: Integer

      belongs_to :building, touch: true, class_name: "TouchableSpec::Referenced::Building"
    end
  end
end
