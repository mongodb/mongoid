module Mongoloid

  class InvalidAssociationError < RuntimeError
  end

  class Association

    TYPES = [:has_many, :has_one, :belongs_to]

    attr_accessor :type, :class_name, :instance

    # Create a new Association which is a relationship between Models.
    # All associations will be treated as a single Document in the database.
    def initialize(type, class_name, instance)
      raise InvalidAssociationError unless TYPES.include?(type)
      @type, @class_name, @instance = type, class_name, instance
    end

  end

end