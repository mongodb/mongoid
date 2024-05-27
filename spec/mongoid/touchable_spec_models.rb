# frozen_string_literal: true
# rubocop:todo all

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

      field :last_used_at, type: Time
      field :level, type: Integer

      embedded_in :building, touch: false, class_name: "TouchableSpec::Embedded::Building"

      embeds_many :keypads, class_name: "TouchableSpec::Embedded::Keypad"
      embeds_many :cameras, class_name: "TouchableSpec::Embedded::Camera"
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :level, type: Integer
      field :last_used_at, type: Time

      embedded_in :building, touch: true, class_name: "TouchableSpec::Embedded::Building"

      embeds_many :chairs, class_name: "TouchableSpec::Embedded::Chair"
      embeds_many :sofas, class_name: "TouchableSpec::Embedded::Sofa"
    end

    class Keypad
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :entrance, touch: false, class_name: "TouchableSpec::Embedded::Entrance"
    end

    class Camera
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :entrance, touch: true, class_name: "TouchableSpec::Embedded::Entrance"
    end

    class Chair
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :floor, touch: false, class_name: "TouchableSpec::Embedded::Floor"
    end

    class Sofa
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :floor, touch: true, class_name: "TouchableSpec::Embedded::Floor"
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

      field :level, type: Integer

      belongs_to :building, touch: false, class_name: "TouchableSpec::Referenced::Building"

      embeds_many :keypads, class_name: "TouchableSpec::Referenced::Keypad"
      embeds_many :cameras, class_name: "TouchableSpec::Referenced::Camera"

      has_many :plants, class_name: "TouchableSpec::Referenced::Plant"
      has_many :windows, class_name: "TouchableSpec::Referenced::Window"
    end

    class Floor
      include Mongoid::Document
      include Mongoid::Timestamps

      field :level, type: Integer

      belongs_to :building, touch: true, class_name: "TouchableSpec::Referenced::Building"

      embeds_many :chairs, class_name: "TouchableSpec::Referenced::Chair"
      embeds_many :sofas, class_name: "TouchableSpec::Referenced::Sofa"

      has_many :plants, class_name: "TouchableSpec::Referenced::Plant"
      has_many :windows, class_name: "TouchableSpec::Referenced::Window"
    end

    class Plant
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :floor, touch: false, class_name: "TouchableSpec::Referenced::Floor"
      belongs_to :entrance, touch: false, class_name: "TouchableSpec::Referenced::Entrance"
    end

    class Window
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :floor, touch: true, class_name: "TouchableSpec::Referenced::Floor"
      belongs_to :entrance, touch: true, class_name: "TouchableSpec::Referenced::Entrance"
    end

    class Keypad
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :entrance, touch: false, class_name: "TouchableSpec::Referenced::Entrance"
    end

    class Camera
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :entrance, touch: true, class_name: "TouchableSpec::Referenced::Entrance"
    end

    class Chair
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :floor, touch: false, class_name: "TouchableSpec::Referenced::Floor"
    end

    class Sofa
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :floor, touch: true, class_name: "TouchableSpec::Referenced::Floor"
    end

    class Label
      include Mongoid::Document
      include Mongoid::Timestamps

      field :bands_updated_at, type: DateTime
      has_many :bands, class_name: "TouchableSpec::Referenced::Band"
    end
    
    class Band
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :label, touch: :bands_updated_at, class_name: "TouchableSpec::Referenced::Label"
    end
    
  end
end
