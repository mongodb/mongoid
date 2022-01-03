# frozen_string_literal: true

class EmmCongress
  include Mongoid::Document
  include Mongoid::Timestamps

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

class EmmInner
  include Mongoid::Document

  embeds_many :friends, :class_name => self.name, :cyclic => true
  embedded_in :parent, :class_name => self.name, :cyclic => true

  field :level, :type => Integer
end

class EmmOuter
  include Mongoid::Document
  embeds_many :inners, class_name: 'EmmInner'

  field :level, :type => Integer
end
