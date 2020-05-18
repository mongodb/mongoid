# frozen_string_literal: true
# encoding: utf-8

class EmmCongress
  include Mongoid::Document

  embeds_many :legislators, class_name: 'EmmLegislator'

  field :name, type: String
end

class EmmLegislator
  include Mongoid::Document

  embedded_in :congress, class_name: 'EmmCongress'

  field :a, type: Integer, default: 0
  field :b, type: Integer, default: 0
end

# Models with associations with :class_name as a :: prefixed string

class EmmCcCongress
  include Mongoid::Document

  embeds_many :legislators, class_name: '::EmmCcLegislator'

  field :name, type: String
end

class EmmCcLegislator
  include Mongoid::Document

  embedded_in :congress, class_name: '::EmmCcCongress'

  field :a, type: Integer, default: 0
  field :b, type: Integer, default: 0
end

class EmmManufactory
  include Mongoid::Document

  embeds_many :products, order: :id.desc, class_name: 'EmmProduct'
end


class EmmProduct
  include Mongoid::Document

  embedded_in :manufactory, class_name: 'EmmManufactory'

  field :name, type: String
end
