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
