# frozen_string_literal: true
# encoding: utf-8

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
end
