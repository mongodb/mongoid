# frozen_string_literal: true
# encoding: utf-8

class EomParent
  include Mongoid::Document

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
