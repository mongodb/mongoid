module Mongoloid

  class InvalidAssociationError < RuntimeError
  end

  class Association

    TYPES = [:has_many, :has_one, :belongs_to]

    attr_reader :type, :klass, :instance

    # Create a new Association which is a relationship between Models.
    # All associations will be treated as a single Document in the database.
    def initialize(type, klass, instance)
      raise InvalidAssociationError unless TYPES.include?(type)
      @type, @klass, @instance = type, klass, instance
    end

  end

end