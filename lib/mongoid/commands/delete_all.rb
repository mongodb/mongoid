# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class DeleteAll
      # Performs a delete of the all the +Documents+ that match the criteria
      # supplied.
      #
      # Options:
      #
      # params: A set of conditions to find the +Documents+ by.
      # klass: The class of the +Document+ to execute the find on.
      #
      # Example:
      #
      # <tt>DeleteAll.execute(Person, :conditions => { :field => "value" })</tt>
      def self.execute(klass, params = {})
        safe = Mongoid.persist_in_safe_mode
        collection = klass.collection
        selector = (params[:conditions] || {}).merge(:_type => klass.name)
        matching = collection.find(selector).count
        collection.remove(selector, :safe => safe) ? matching : 0
      end
    end
  end
end
