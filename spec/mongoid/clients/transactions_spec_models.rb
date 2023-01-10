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

module TransactionsSpecCountable
  def after_commit_counter
    @after_commit_counter ||= TransactionsSpecCounter.new
  end

  def after_commit_counter=(new_counter)
    @after_commit_counter = new_counter
  end

  def after_rollback_counter
    @after_rollback_counter ||= TransactionsSpecCounter.new
  end

  def after_rollback_counter=(new_counter)
    @after_rollback_counter = new_counter
  end
end

class TransactionsSpecPerson
  include Mongoid::Document
  include TransactionsSpecCountable

  field :name, type: String

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end

class TransactionSpecRaisesBeforeSave
  include Mongoid::Document
  include TransactionsSpecCountable

  field :attr, type: String

  before_save do
    raise "I cannot be saved"
  end

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end

class TransactionSpecRaisesAfterSave
  include Mongoid::Document
  include TransactionsSpecCountable

  field :attr, type: String

  after_save do
    raise "I cannot be saved"
  end

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end
