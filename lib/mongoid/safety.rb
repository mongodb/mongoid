# encoding: utf-8
module Mongoid #:nodoc:

  # The +Safety+ module is used to provide a DSL to execute database operations
  # in safe mode on a per query basis, either from the +Document+ class level
  # or instance level.
  module Safety
    extend ActiveSupport::Concern

    # Execute the following class-level persistence operation in safe mode.
    #
    # @example Upsert in safe mode.
    #   person.safely.upsert
    #
    # @example Destroy in safe mode with w and fsync options.
    #   person.safely(:w => 2, :fsync => true).destroy
    #
    # @param [ Hash ] options The safe mode options.
    #
    # @option options [ Integer ] :w The number of nodes to write to.
    # @option options [ Integer ] :wtimeout Time to wait for return from all
    #   nodes.
    # @option options [ true, false ] :fsync Should a fsync occur.
    #
    # @return [ Proxy ] The safety proxy.
    def safely(safety = true)
      Proxy.new(self, safety)
    end

    module ClassMethods #:nodoc:

      # Execute the following class-level persistence operation in safe mode.
      #
      # @example Create in safe mode.
      #   Person.safely.create(:name => "John")
      #
      # @example Delete all in safe mode with options.
      #   Person.safely(:w => 2, :fsync => true).delete_all
      #
      # @param [ Hash ] options The safe mode options.
      #
      # @option options [ Integer ] :w The number of nodes to write to.
      # @option options [ Integer ] :wtimeout Time to wait for return from all
      #   nodes.
      # @option options [ true, false ] :fsync Should a fsync occur.
      #
      # @return [ Proxy ] The safety proxy.
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

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not.
      #
      # @example Safely create a document.
      #   Person.safely.create(:title => "Mr")
      #
      # @param [ Hash ] attributes The attributes to create with.
      #
      # @return [ Document ] The new document.
      def create(attributes = {})
        target.new(attributes).tap { |doc| doc.insert(:safe => safety_options) }
      end

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not, and if validation fails an error will be
      # raise.
      #
      # @example Safely create a document.
      #   Person.safely.create!(:title => "Mr")
      #
      # @param [ Hash ] attributes The attributes to create with.
      #
      # @raise [ Errors::Validations ] If validation failed.
      #
      # @return [ Document ] If validation passed.
      def create!(attributes = {})
        target.new(attributes).tap do |document|
          fail_validate!(document) if document.insert(:safe => safety_options).errors.any?
        end
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Does not fire any callbacks.
      #
      # @example Delete all documents.
      #   Person.safely.delete_all
      #
      # @example Conditionally delete all documents.
      #   Person.safely.delete_all(:conditions => { :title => "Sir" })
      #
      # @param [ Hash ] conditions The conditions to delete with.
      #
      # @return [ Integer ] The number of documents deleted.
      def delete_all(conditions = {})
        Mongoid::Persistence::RemoveAll.new(
          target,
          { :validate => false, :safe => safety_options },
          conditions[:conditions] || {}
        ).persist
      end

      # destroy all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Fires the destroy callbacks if conditions were passed.
      #
      # @example destroy all documents.
      #   Person.safely.destroy_all
      #
      # @example Conditionally destroy all documents.
      #   Person.safely.destroy_all(:conditions => { :title => "Sir" })
      #
      # @param [ Hash ] conditions The conditions to destroy with.
      #
      # @return [ Integer ] The number of documents destroyd.
      def destroy_all(conditions = {})
        documents = target.all(conditions)
        documents.count.tap do |count|
          documents.each { |doc| doc.destroy(:safe => safety_options) }
        end
      end

      # Increment the field by the provided value, else if it doesn't exists set
      # it to that value.
      #
      # @example Safely increment a field.
      #   person.safely.inc(:age, 1)
      #
      # @param [ Symbol, String ] field The field to increment.
      # @param [ Integer ] value The value to increment by.
      # @param [ Hash ] options Options to pass through to the driver.
      def inc(field, value, options = {})
        target.inc(field, value, :safe => safety_options)
      end

      # Create the new +Proxy+.
      #
      # @example Create the proxy.
      #   Proxy.new(document, :w => 3)
      #
      # @param [ Document, Class ] target Either the class or the instance.
      # @param [ true, Hash ] safety_options The options.
      def initialize(target, safety_options)
        @target = target
        @safety_options = safety_options
      end

      # We will use method missing to proxy calls to the target.
      #
      # @example Save safely.
      #   person.safely.save
      #
      # @param [ Array ] *args The arguments to pass on.
      def method_missing(*args)
        name = args[0]
        attributes = args[1] || {}
        target.send(name, attributes.merge(:safe => safety_options))
      end

      # Update the +Document+ attributes in the datbase.
      #
      # @example Safely update attributes.
      #   person.safely.update_attributes(:title => "Sir")
      #
      # @param [ Hash ] attributes The attributes to update.
      #
      # @return [ true, false ] Whether the document was saved.
      def update_attributes(attributes = {})
        target.write_attributes(attributes)
        target.update(:safe => safety_options)
      end

      # Update the +Document+ attributes in the datbase.
      #
      # @example Safely update attributes.
      #   person.safely.update_attributes(:title => "Sir")
      #
      # @param [ Hash ] attributes The attributes to update.
      #
      # @raise [ Errors::Validations ] If validation failed.
      #
      # @return [ true ] If the document was saved.
      def update_attributes!(attributes = {})
        target.write_attributes(attributes)
        update(:safe => safety_options).tap do |result|
          target.class.fail_validate!(target) unless result
        end
      end
    end
  end
end
