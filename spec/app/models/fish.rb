class Fish
  include Mongoid::Document

  def self.fresh
    where(fresh: true)
  end
end
