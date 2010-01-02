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
        collection = klass.collection
        params.any? ? collection.remove(params[:conditions].merge(:_type => klass.name)) : collection.drop
      end
    end
  end
end
