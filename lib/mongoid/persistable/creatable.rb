# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that create new documents.
    #
    # @since 2.0.0
    module Creatable
      extend ActiveSupport::Concern

      module ClassMethods

        # Create a new document. This will instantiate a new document and
        # insert it in a single call. Will always return the document
        # whether save passed or not.
        #
        # @example Create a new document.
        #   Person.create(:title => "Mr")
        #
        # @example Create multiple new documents.
        #   Person.create({ title: "Mr" }, { title: "Mrs" })
        #
        # @param [ Hash, Array ] attributes The attributes to create with, or an
        #   Array of multiple attributes for multiple documents.
        #
        # @return [ Document, Array<Document> ] The newly created document(s).
        #
        # @since 1.0.0
        def create(attributes = nil, &block)
          _creating do
            if attributes.is_a?(::Array)
              attributes.map { |attrs| create(attrs, &block) }
            else
              doc = new(attributes, &block)
              doc.save
              doc
            end
          end
        end

        # Create a new document. This will instantiate a new document and
        # insert it in a single call. Will always return the document
        # whether save passed or not, and if validation fails an error will be
        # raise.
        #
        # @example Create a new document.
        #   Person.create!(:title => "Mr")
        #
        # @example Create multiple new documents.
        #   Person.create!({ title: "Mr" }, { title: "Mrs" })
        #
        # @param [ Hash, Array ] attributes The attributes to create with, or an
        #   Array of multiple attributes for multiple documents.
        # @param [ Hash ] options A mass-assignment protection options. Supports
        #   :as and :without_protection
        #
        # @return [ Document, Array<Document> ] The newly created document(s).
        #
        # @since 1.0.0
        def create!(attributes = nil, &block)
          _creating do
            if attributes.is_a?(::Array)
              attributes.map { |attrs| create!(attrs, &block) }
            else
              doc = new(attributes, &block)
              doc.fail_due_to_validation! unless doc.insert.errors.empty?
              doc.fail_due_to_callback!(:create!) if doc.new_record?
              doc
            end
          end
        end
      end
    end
  end
end
