# frozen_string_literal: true

class EomParent
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_one :child, class_name: 'EomChild'

  field :name, type: String
end

class EomChild
  include Mongoid::Document

  embedded_in :parent, class_name: 'EomParent'

  field :a, type: Integer, default: 0
  field :b, type: Integer, default: 0
end

# Models with associations with :class_name as a :: prefixed string

class EomCcParent
  include Mongoid::Document

  embeds_one :child, class_name: '::EomCcChild'
end

class EomCcChild
  include Mongoid::Document

  embedded_in :parent, class_name: '::EomCcParent'
end

# Models referencing other models which should not be loaded unless the
# respective association is referenced

autoload :EomDnlMissingChild, 'mongoid/association/embedded/embeds_one_dnl_models'

class EomDnlParent
  include Mongoid::Document

  embeds_one :child, class_name: 'EomDnlChild'
  embeds_one :missing_child, class_name: 'EomDnlMissingChild'
end

autoload :EomDnlMissingParent, 'mongoid/association/embedded/embeds_one_dnl_models'

class EomDnlChild
  include Mongoid::Document

  embedded_in :parent, class_name: 'EomDnlParent'
  embedded_in :missing_parent, class_name: 'EomDnlMissingParent'
end

class EomAddress
  include Mongoid::Document

  field :city, type: String

  embedded_in :addressable, polymorphic: true
end

# app/models/company.rb
class EomCompany
  include Mongoid::Document

  embeds_one :address, class_name: 'EomAddress', as: :addressable
  accepts_nested_attributes_for :address

  embeds_one :delivery_address, class_name: 'EomAddress', as: :addressable
  accepts_nested_attributes_for :delivery_address
end
