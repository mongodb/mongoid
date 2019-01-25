module CopyableSpec
  class A
    include Mongoid::Document

    embeds_many :locations
  end

  class Location
    include Mongoid::Document

    embeds_many :buildings
  end

  class Building
    include Mongoid::Document
  end
end
