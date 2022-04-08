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
  end

  class Gun
    include Mongoid::Document

    embedded_in :tank
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
