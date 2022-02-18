class Galaxy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :age, type: Integer
  field :was_touched, type: Mongoid::Boolean, default: false
  before_validation :set_age

  embeds_many :stars

  set_callback(:touch, :before) do |document|
    self.was_touched = true
  end

  private

  def set_age
    self.age ||= 100_000
  end
end

class Star
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :galaxy

  field :age, type: Integer
  field :was_touched_after_parent, type: Mongoid::Boolean, default: false

  before_validation :set_age

  embeds_many :planets

  set_callback(:touch, :before) do |document|
    self.was_touched_after_parent = true if galaxy.was_touched
  end

  private

  def set_age
    self.age ||= 42_000
  end
end

class Planet
  include Mongoid::Document

  embedded_in :star

  field :age, type: Integer
  field :was_touched_after_parent, type: Mongoid::Boolean, default: false

  before_validation :set_age

  set_callback(:touch, :before) do |document|
    self.was_touched_after_parent = true if star.was_touched_after_parent
  end

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
