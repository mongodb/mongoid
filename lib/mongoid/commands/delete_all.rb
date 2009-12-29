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
        params.any? ? klass.find(:all, params).each do
          |doc| Delete.execute(doc)
        end : klass.collection.drop
      end
    end
  end
end
