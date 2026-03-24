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
end
