# frozen_string_literal: true

class Event
  include Mongoid::Document

  field :title
  field :date, type: Date
  has_and_belongs_to_many \
    :administrators,
    class_name: 'Person',
    inverse_of: :administrated_events,
    dependent: :nullify
  belongs_to :owner

  def self.each_day(start_date, end_date)
    groups = only(:date).asc(:date).where(:date.gte => start_date, :date.lte => end_date).group
    groups.each do |hash|
      yield(hash["date"], hash["group"])
    end
  end

  scope :best, ->{ where(:kind.in => [ "party", "concert" ]) }
  scope :by_kind, ->(kind){ where(:kind.in => [kind]) }
end
