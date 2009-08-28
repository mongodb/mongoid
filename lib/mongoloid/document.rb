module Mongoloid
  class Document

    attr_reader :attributes, :collection

    class << self

      def create(attributes = nil)
        new(attributes).save
      end

    end

    def id
      @attributes[:_id]
    end

    #
    # Create a new instance of the document.
    #
    def initialize(attributes = nil)
      @attributes = attributes || {}
      @collection = Mongoloid.database.collection(self.class.to_s.downcase)
    end

    def new_record?
      @attributes[:_id].nil?
    end

    def save
      @collection.save(@attributes)
      self
    end

  end
end
