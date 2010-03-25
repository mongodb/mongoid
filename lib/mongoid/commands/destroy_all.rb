# encoding: utf-8
module Mongoid #:nodoc:
  module Commands
    class DestroyAll
      # Performs a destroy of the all the +Documents+ that match the criteria
      # supplied. Will execute all the destroy callbacks for each +Document+.
      #
      # Options:
      #
      # params: A set of conditions to find the +Documents+ by.
      # klass: The class of the +Document+ to execute the find on.
      #
      # Example:
      #
      # <tt>DestroyAll.execute(Person, :conditions => { :field => "value" })</tt>
      def self.execute(klass, params)
        conditions = params[:conditions] || {}
        params[:conditions] = conditions.merge(:_type => klass.name)
        documents = klass.find(:all, params)
        matching = documents.count
        documents.each { |doc| Destroy.execute(doc) }; matching
      end
    end
  end
end
