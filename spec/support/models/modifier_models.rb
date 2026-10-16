# frozen_string_literal: true

module ModifierModels
  class Cabinet
    include Mongoid::Document

    embeds_one :drawer, class_name: 'ModifierModels::Drawer', autobuild: true
  end

  class Drawer
    include Mongoid::Document

    field :matcher, type: String
    embedded_in :cabinet, class_name: 'ModifierModels::Cabinet'
    embeds_many :items, class_name: 'ModifierModels::Item'
  end

  class Item
    include Mongoid::Document

    field :name, type: String
    embedded_in :drawer, class_name: 'ModifierModels::Drawer'
    embeds_many :widgets, class_name: 'ModifierModels::Widget'
  end

  class Widget
    include Mongoid::Document

    field :label, type: String
    embedded_in :item, class_name: 'ModifierModels::Item'
  end
end
