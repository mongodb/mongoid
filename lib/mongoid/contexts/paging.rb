# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    module Paging
      # Paginates the documents.
      #
      # Example:
      #
      # <tt>context.paginate</tt>
      #
      # Returns:
      #
      # A collection of documents paginated.
      def paginate
        @collection ||= execute(true)
        WillPaginate::Collection.create(page, per_page, count) do |pager|
          pager.replace(@collection.to_a)
        end
      end

      # Either returns the page option and removes it from the options, or
      # returns a default value of 1.
      #
      # Returns:
      #
      # An +Integer+ page number.
      def page
        skips, limits = options[:skip], options[:limit]
        (skips && limits) ? (skips + limits) / limits : 1
      end

      # Get the number of results per page or the default of 20.
      #
      # Returns:
      #
      # The +Integer+ number of documents in each page.
      def per_page
        (options[:limit] || 20).to_i
      end
    end
  end
end
