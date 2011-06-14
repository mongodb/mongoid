class Event
  include Mongoid::Document

  field :title
  field :date, :type => Date
  references_and_referenced_in_many \
    :administrators,
    :class_name => 'Person',
    :inverse_of => :administrated_events,
    :dependent => :nullify
  referenced_in :owner

  def self.each_day(start_date, end_date)
    groups = only(:date).asc(:date).where(:date.gte => start_date, :date.lte => end_date).group
    groups.each do |hash|
      yield(hash["date"], hash["group"])
    end
  end

end
