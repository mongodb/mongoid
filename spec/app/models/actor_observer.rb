class ActorObserver < Mongoid::Observer
  attr_reader :last_after_create_record
  def after_create(record)
    @last_after_create_record = record
  end
end
