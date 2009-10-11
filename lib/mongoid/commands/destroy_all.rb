module Mongoid #:nodoc:
  module Commands
    class DestroyAll #:nodoc:
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
        klass.find(:all, params).each { |doc| Destroy.execute(doc) }
      end
    end
  end
end
