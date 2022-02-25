# frozen_string_literal: true

class HomCollege
  include Mongoid::Document

  has_one :accreditation, class_name: 'HomAccreditation'

  # The address is added with different dependency mechanisms in tests:
  #has_one :address, class_name: 'HomAddress', dependent: :destroy

  field :state, type: String
end

class HomAccreditation
  include Mongoid::Document

  belongs_to :college, class_name: 'HomCollege'

  field :degree, type: String
  field :year, type: Integer, default: 2012

  def format
    'fmt'
  end

  def price
    42
  end
end

class HomAccreditation::Child
  include Mongoid::Document

  belongs_to :hom_college
end

class HomAddress
  include Mongoid::Document

  belongs_to :college, class_name: 'HomCollege'
end

module HomNs
  class PrefixedParent
    include Mongoid::Document

    has_one :child, class_name: 'PrefixedChild'
  end

  class PrefixedChild
    include Mongoid::Document

    belongs_to :parent, class_name: 'PrefixedParent'
  end
end

class HomPolymorphicParent
  include Mongoid::Document

  has_one :p_child, as: :parent
end

class HomPolymorphicChild
  include Mongoid::Document

  belongs_to :p_parent, polymorphic: true
end

class HomBus
  include Mongoid::Document

  has_one :driver, class_name: 'HomBusDriver'
end

class HomBusDriver
  include Mongoid::Document

  # No belongs_to :bus
end

class HomTrainer
  include Mongoid::Document

  field :name, type: String

  has_one :animal, class_name: 'HomAnimal', scope: :reptile
end

class HomAnimal
  include Mongoid::Document

  field :taxonomy, type: String

  scope :reptile, -> { where(taxonomy: 'reptile') }

  belongs_to :trainer, class_name: 'HomTrainer', scope: -> { where(name: 'Dave') }
end

class HomPost
  include Mongoid::Document

  field :title, type: String

  has_one :comment, inverse_of: :post, class_name: 'HomComment'
end

class HomComment
  include Mongoid::Document

  field :content, type: String

  belongs_to :post, inverse_of: :comment, optional: true, class_name: 'HomPost'
end
