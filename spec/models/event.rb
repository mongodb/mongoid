class Event
  include Mongoid::Document

  references_and_referenced_in_many \
    :administrators,
    :class_name => 'Person',
    :inverse_of => :administrated_events,
    :dependent => :nullify
end
