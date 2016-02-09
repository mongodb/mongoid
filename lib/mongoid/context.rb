module Mongoid

  class Context


    def initialize(object)
      @write_concern = Mongo::WriteConcern.get(w: 1)#object.write_concern
      @read_preference = Mongo::ServerSelector.get(mode: :primary)#object.read_preference
    end
  end
end