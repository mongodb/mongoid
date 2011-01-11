# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Exclusion
      # Adds a criterion to the +Criteria+ that specifies values that are not allowed
      # to match any document in the database. The MongoDB conditional operator that
      # will be used is "$ne".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is a
      # value that must not be equal to the corresponding field value in the database.
      #
      # Example:
      #
      # <tt>criteria.excludes(:field => "value1")</tt>
      #
      # <tt>criteria.excludes(:field1 => "value1", :field2 => "value1")</tt>
      #
      # Returns: <tt>self</tt>
      def excludes(attributes = {})
        mongo_id = attributes.delete(:id)
        attributes = attributes.merge(:_id => mongo_id) if mongo_id
        update_selector(attributes, "$ne")
      end

      # Adds a criterion to the +Criteria+ that specifies values where none
      # should match in order to return results. This is similar to an SQL "NOT IN"
      # clause. The MongoDB conditional operator that will be used is "$nin".
      #
      # Options:
      #
      # attributes: A +Hash+ where the key is the field name and the value is an
      # +Array+ of values that none can match.
      #
      # Example:
      #
      # <tt>criteria.not_in(:field => ["value1", "value2"])</tt>
      #
      # <tt>criteria.not_in(:field1 => ["value1", "value2"], :field2 => ["value1"])</tt>
      #
      # Returns: <tt>self</tt>
      def not_in(attributes)
        update_selector(attributes, "$nin")
      end

      # Adds a criterion to the +Criteria+ that specifies the fields that will
      # get returned from the Document. Used mainly for list views that do not
      # require all fields to be present. This is similar to SQL "SELECT" values.
      #
      # Options:
      #
      # args: A list of field names to retrict the returned fields to.
      #
      # Example:
      #
      # <tt>criteria.only(:field1, :field2, :field3)</tt>
      #
      # Returns: <tt>self</tt>
      def only(*args)
        clone.tap do |crit|
          crit.options[:fields] = args.flatten if args.any?
        end
      end
    end
  end
end
