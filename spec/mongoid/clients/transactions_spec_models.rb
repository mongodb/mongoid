# rubocop:todo all
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

  def reset
    @called = 0
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

class TransactionsSpecPersonWithOnCreate
  include Mongoid::Document
  include TransactionsSpecCountable

  field :name, type: String

  after_commit on: :create do
    after_commit_counter.inc
  end

  after_rollback on: :create do
    after_rollback_counter.inc
  end
end

class TransactionsSpecPersonWithOnUpdate
  include Mongoid::Document
  include TransactionsSpecCountable

  field :name, type: String

  after_commit on: :update do
    after_commit_counter.inc
  end

  after_rollback on: :update do
    after_rollback_counter.inc
  end
end

class TransactionsSpecPersonWithOnDestroy
  include Mongoid::Document
  include TransactionsSpecCountable

  field :name, type: String

  after_commit on: :destroy do
    after_commit_counter.inc
  end

  after_rollback on: :destroy do
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

class TransactionSpecRaisesBeforeCreate
  include Mongoid::Document

  def self.after_commit_counter
    @@after_commit_counter ||= TransactionsSpecCounter.new
  end

  def self.after_rollback_counter
    @@after_rollback_counter ||= TransactionsSpecCounter.new
  end

  field :attr, type: String

  before_create do
    raise "I cannot be saved"
  end

  after_commit do
    self.class.after_commit_counter.inc
  end

  after_rollback do
    self.class.after_rollback_counter.inc
  end
end
