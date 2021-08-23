# frozen_string_literal: true

module CopyableSpec
  class A
    include Mongoid::Document

    embeds_many :locations
    embeds_many :influencers
  end

  class Location
    include Mongoid::Document

    embeds_many :buildings
  end

  class Building
    include Mongoid::Document
  end

  class Influencer
    include Mongoid::Document

    embeds_many :blurbs
  end

  class Youtuber < Influencer
  end

  class Blurb
    include Mongoid::Document
  end

  # Do not include Attributes::Dynamic
  class Reg
    include Mongoid::Document

    field :name, type: String
  end

  class Dyn
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    field :name, type: String
  end
end
