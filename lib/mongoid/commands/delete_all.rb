module Mongoid #:nodoc:
  module Commands
    class DeleteAll #:nodoc:
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
      def self.execute(klass, params)
        klass.find(:all, params).each { |doc| Delete.execute(doc) }
      end
    end
  end
end
