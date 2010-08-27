# encoding: utf-8
module Mongoid #:nodoc:

  # The +Safety+ module is used to provide a DSL to execute database operations
  # in safe mode on a per query basis, either from the +Document+ class level
  # or instance level.
  module Safety
    extend ActiveSupport::Concern

    # Execute the following class-level persistence operation in safe mode.
    #
    # Example:
    #
    # <tt>person.safely.upsert</tt>
    # <tt>person.safely(:w => 2, :fsync => true).destroy</tt>
    #
    # Returns:
    #
    # A +Proxy+ to the +Document+.
    def safely(safety = true)
      Proxy.new(self, safety)
    end

    module ClassMethods #:nodoc:

      # Execute the following class-level persistence operation in safe mode.
      #
      # Example:
      #
      # <tt>Person.safely.create(:name => "John")</tt>
      # <tt>Person.safely(:w => 2, :fsync => true).delete_all</tt>
      #
      # Returns:
      #
      # A +Proxy+ to the +Document+ class.
      def safely(safety = true)
        Proxy.new(self, safety)
      end
    end

    # When this class proxies a document or class, the next persistence
    # operation executed on it will query in safe mode.
    #
    # Operations that took a hash of attributes had to be somewhat duplicated
    # here since we do not want to allow a :safe attribute to be included in
    # the args. This is because safe could be a common attribute name and we
    # don't want the collision between the attribute and determining whether or
    # not safe mode is allowed.
    class Proxy

      attr_reader :target, :safety_options

      # Create the new +Proxy+.
      #
      # Options:
      #
      # target: Either the class or the instance.
      # safety_options: true or a hash of options
      def initialize(target, safety_options)
        @target = target
        @safety_options = safety_options
      end

      # We will use method missing to proxy calls to the target.
      #
      # Example:
      #
      # <tt>person.safely.save</tt>
      def method_missing(*args)
        name = args[0]
        attributes = args[1] || {}
        @target.send(name, attributes.merge(:safe => safety_options))
      end

      # Increment the field by the provided value, else if it doesn't exists set
      # it to that value.
      #
      # Options:
      #
      # field: The field to increment.
      # value: The value to increment by.
      # options: Options to pass through to the driver.
      def inc(field, value, options = {})
        @target.inc(field, value, :safe => safety_options)
      end

      # Update the +Document+ attributes in the datbase.
      #
      # Example:
      #
      # <tt>document.update_attributes(:title => "Sir")</tt>
      #
      # Returns:
      #
      # +true+ if validation passed, +false+ if not.
      def update_attributes(attributes = {})
        @target.write_attributes(attributes)
        @target.update(:safe => safety_options)
      end

      # Update the +Document+ attributes in the datbase.
      #
      # Example:
      #
      # <tt>document.update_attributes(:title => "Sir")</tt>
      #
      # Returns:
      #
      # +true+ if validation passed, raises an error if not
      def update_attributes!(attributes = {})
        @target.write_attributes(attributes)
        result = update(:safe => safety_options)
        @target.class.fail_validate!(self) unless result
        result
      end

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not.
      #
      # Example:
      #
      # <tt>Person.create(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create(attributes = {})
        @target.new(attributes).tap { |doc| doc.insert(:safe => safety_options) }
      end

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not, and if validation fails an error will be
      # raise.
      #
      # Example:
      #
      # <tt>Person.create!(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create!(attributes = {})
        document = @target.new(attributes)
        fail_validate!(document) if document.insert(:safe => safety_options).errors.any?
        document
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Does not fire any callbacks.
      #
      # Example:
      #
      # <tt>Person.delete_all(:conditions => { :title => "Sir" })</tt>
      # <tt>Person.delete_all</tt>
      #
      # Returns: true or raises an error.
      def delete_all(conditions = {})
        Mongoid::Persistence::RemoveAll.new(
          @target,
          { :validate => false, :safe => safety_options },
          conditions[:conditions] || {}
        ).persist
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Fires the destroy callbacks if conditions were passed.
      #
      # Example:
      #
      # <tt>Person.destroy_all(:conditions => { :title => "Sir" })</tt>
      # <tt>Person.destroy_all</tt>
      #
      # Returns: true or raises an error.
      def destroy_all(conditions = {})
        documents = @target.all(conditions)
        count = documents.count
        documents.each { |doc| doc.destroy(:safe => safety_options) }
        count
      end
    end
  end
end
