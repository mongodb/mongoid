class TransactionsSpecCounter
  def initialize
    @called = 0
  end

  def inc
    @called += 1
  end

  def value
    @called
  end
end

class TransactionsSpecPerson
  include Mongoid::Document

  field :name, type: String

  attr_accessor :after_commit_counter

  def after_commit_counter
    @after_commit_counter ||= TransactionsSpecCounter.new
  end

  after_commit do
    after_commit_counter.inc
  end

  attr_accessor :after_rollback_counter

  def after_rollback_counter
    @after_rollback_counter ||= TransactionsSpecCounter.new
  end

  after_rollback do
    after_rollback_counter.inc
  end
end
