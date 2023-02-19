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

class EmmCustomerAddress
  include Mongoid::Document

  embedded_in :addressable, polymorphic: true, inverse_of: :work_address
end

class EmmFriend
  include Mongoid::Document

  embedded_in :befriendable, polymorphic: true
end

class EmmCustomer
  include Mongoid::Document

  embeds_one :home_address, class_name: 'EmmCustomerAddress', as: :addressable
  embeds_one :work_address, class_name: 'EmmCustomerAddress', as: :addressable

  embeds_many :close_friends, class_name: 'EmmFriend', as: :befriendable
  embeds_many :acquaintances, class_name: 'EmmFriend', as: :befriendable
end

class EmmUser
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :orders, class_name: 'EmmOrder'
end

class EmmOrder
  include Mongoid::Document

  field :sku
  field :amount, type: Integer

  embedded_in :user, class_name: 'EmmUser'
end

module EmmSpec
  # There is also a top-level Car class defined.
  class Car
    include Mongoid::Document

    embeds_many :doors
  end

  class Door
    include Mongoid::Document

    embedded_in :car
  end

  class Tank
    include Mongoid::Document

    embeds_many :guns
    embeds_many :emm_turrets
    # This association references a model that is not in our module,
    # and it does not define class_name hence Mongoid will not be able to
    # figure out the inverse for this association.
    embeds_many :emm_hatches

    # class_name is intentionally unqualified, references a class in the
    # same module. Rails permits class_name to be unqualified like this.
    embeds_many :launchers, class_name: 'Launcher'
  end

  class Gun
    include Mongoid::Document

    embedded_in :tank
  end

  class Launcher
    include Mongoid::Document

    # class_name is intentionally unqualified.
    embedded_in :tank, class_name: 'Tank'
  end
end

# This is intentionally on top level.
class EmmTurret
  include Mongoid::Document

  embedded_in :tank, class_name: 'EmmSpec::Tank'
end

# This is intentionally on top level.
class EmmHatch
  include Mongoid::Document

  # No :class_name option on this association intentionally.
  embedded_in :tank
end

class EmmPost
  include Mongoid::Document

  embeds_many :company_tags, class_name: "EmmCompanyTag"
  embeds_many :user_tags, class_name: "EmmUserTag"
end


class EmmCompanyTag
  include Mongoid::Document

  field :title, type: String

  embedded_in :post, class_name: "EmmPost"
end


class EmmUserTag
  include Mongoid::Document

  field :title, type: String

  embedded_in :post, class_name: "EmmPost"
end

class EmmSchool
  include Mongoid::Document

  embeds_many :students, class_name: "EmmStudent"

  field :name, type: :string

  validates :name, presence: true
end

class EmmStudent
  include Mongoid::Document

  embedded_in :school, class_name: "EmmSchool"
end

class EmmParent
  include Mongoid::Document
  embeds_many :blocks, class_name: "EmmBlock"
end

class EmmBlock
  include Mongoid::Document
  field :name, type: String
  embeds_many :children, class_name: "EmmChild"
end

class EmmChild
  include Mongoid::Document
  embedded_in :block, class_name: "EmmBlock"

  field :size, type: Integer
  field :order, type: Integer
  field :t
end

