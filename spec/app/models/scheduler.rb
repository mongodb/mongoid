class Scheduler
  include Mongoid::Document

  def strategy
    Strategy.new
  end
end
