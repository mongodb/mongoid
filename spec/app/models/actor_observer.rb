class ActorObserver < Mongoid::Observer
  attr_reader :last_after_create_record

  def after_create(record)
    @last_after_create_record = record
  end

  def after_custom(record)
    record.after_custom_count += 1
  end

  def before_custom(record)
    @after_custom_called = true
  end
end
