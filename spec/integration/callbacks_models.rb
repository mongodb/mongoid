class Galaxy
  include Mongoid::Document

  field :age, type: Integer

  before_validation :set_age

  embeds_many :stars

  private

  def set_age
    self.age ||= 100_000
  end
end

class Star
  include Mongoid::Document

  embedded_in :galaxy

  field :age, type: Integer

  before_validation :set_age

  embeds_many :planets

  private

  def set_age
    self.age ||= 42_000
  end
end

class Planet
  include Mongoid::Document

  embedded_in :star

  field :age, type: Integer

  before_validation :set_age

  private

  def set_age
    self.age ||= 2_000
  end
end

class Emission
  include Mongoid::Document

  field :frequency

  after_save do
    @previous = attribute_was(:frequency)
  end

  attr_reader :previous
end

class Country
  include Mongoid::Document

  field :age

  before_validation :set_age

  embeds_one :president

  private

  def set_age
    self.age ||= 245
  end
end

class President
  include Mongoid::Document

  embedded_in :country

  field :age

  field :name

  before_validation :set_age

  embeds_one :first_spouse

  private

  def set_age
    self.age ||= 79
  end
end

class FirstSpouse
  include Mongoid::Document

  embedded_in :president

  field :name
  field :age, type: Integer

  before_validation :set_age

  private

  def set_age
    self.age ||= 70
  end
end
