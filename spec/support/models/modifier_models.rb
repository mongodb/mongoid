# frozen_string_literal: true

module ModifierModels
  class Library
    include Mongoid::Document

    field :name, type: String
    embeds_many :books, class_name: 'ModifierModels::Book'
  end

  class Book
    include Mongoid::Document

    embedded_in :library, class_name: 'ModifierModels::Library'
    field :title, type: String
    embeds_one :foreword, class_name: 'ModifierModels::Foreword'
  end

  class Foreword
    include Mongoid::Document

    embedded_in :book, class_name: 'ModifierModels::Book'
    field :text, type: String
  end

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
