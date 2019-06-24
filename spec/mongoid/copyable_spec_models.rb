# frozen_string_literal: true
# encoding: utf-8

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
