class Thing
  include Mongoid::Document
  before_destroy :dont_do_it
  embedded_in :actor

  def dont_do_it
    false
  end
end
