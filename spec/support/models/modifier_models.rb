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

  class Roster
    include Mongoid::Document

    embeds_many :players, class_name: 'ModifierModels::Player'
  end

  class Player
    include Mongoid::Document

    embedded_in :roster, class_name: 'ModifierModels::Roster'
    embeds_one :medal, class_name: 'ModifierModels::Medal'
    has_and_belongs_to_many :badges, inverse_of: nil, class_name: 'ModifierModels::Badge'
    field :nickname, type: String
  end

  class Medal
    include Mongoid::Document

    embedded_in :player, class_name: 'ModifierModels::Player'
  end

  class Badge
    include Mongoid::Document
  end
end
