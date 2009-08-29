module Mongoloid
  class Document

    attr_reader :attributes

    class << self

      def collection
        @collection ||= Mongoloid.database.collection(self.class.to_s.downcase)
      end

      def create(attributes = nil)
        new(attributes).save
      end

      def find(selector = nil)
        collection.find(selector).collect { |doc| new(doc) }
      end

    end

    def collection
      self.class.collection
    end

    def id
      @attributes[:_id]
    end

    def initialize(attributes = nil)
      @attributes = attributes || {}
    end

    def new_record?
      @attributes[:_id].nil?
    end

    def save
      collection.save(@attributes)
      self
    end

  end
end
