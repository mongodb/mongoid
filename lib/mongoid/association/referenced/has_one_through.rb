# frozen_string_literal: true

require 'mongoid/association/referenced/has_one_through/proxy'
require 'mongoid/association/referenced/has_one_through/eager'

module Mongoid
  module Association
    module Referenced
      # Metadata class for has_one :through associations.
      class HasOneThrough
        include Relatable

        # The options available for this type of association, in addition to the
        # common ones.
        #
        # @return [ Array<Symbol> ] The extra valid options.
        ASSOCIATION_OPTIONS = %i[source through scope].freeze

        # The complete list of valid options for this association, including
        # the shared ones.
        #
        # @return [ Array<Symbol> ] The valid options.
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        # The list of association complements.
        #
        # @return [ Array ]
        def relation_complements
          [].freeze
        end

        # Setup instance methods on the owner class.
        #
        # @return [ self ]
        def setup!
          setup_instance_methods!
          self
        end

        # Is this association embedded?
        #
        # @return [ false ]
        def embedded?
          false
        end

        # The proxy class for this association type.
        #
        # @return [ Class ]
        def relation
          Proxy
        end

        # The intermediate association metadata on the owner class.
        # Resolved lazily to allow forward references.
        #
        # @return [ Mongoid::Association::Relatable ]
        def through_association
          @through_association ||= begin
            assoc = @owner_class.relations[@options[:through].to_s] ||
                    raise(
                      Errors::InvalidRelationOption.new(
                        @owner_class, name, :through, @options[:through]
                      )
                    )
            if assoc.embedded?
              raise(
                Errors::InvalidRelationOption.new(
                  @owner_class, name, :through,
                  'through association must be a referenced association, not embedded'
                )
              )
            end
            assoc
          end
        end

        # The source association metadata on the intermediate class.
        # Resolved lazily to allow forward references.
        #
        # @return [ Mongoid::Association::Relatable ]
        def source_association
          @source_association ||= begin
            source_name = (@options[:source] || name).to_s
            through_association.klass.relations[source_name] ||
              raise(
                Errors::InvalidRelationOption.new(
                  @owner_class, name, :source, source_name
                )
              )
          end
        end

        # Through associations never store a foreign key on the owner document.
        #
        # @return [ false ]
        def stores_foreign_key?
          false
        end

        # Resolve the target by delegating through the intermediate proxy.
        # Unlike other association types, this returns a document (or nil)
        # directly rather than a Mongoid::Criteria, because the two-hop
        # traversal is performed eagerly via the existing association proxy.
        #
        # @param [ Document ] base The owner document.
        #
        # @return [ Document | nil ]
        def criteria(base)
          through_target = base.public_send(through_association.name)
          return nil if through_target.nil?

          through_target.public_send(source_association.name)
        end

        # The default for validating the association object.
        #
        # @return [ false ]
        def validation_default
          false
        end

        private

        def setup_instance_methods!
          define_through_getter!
          define_readonly_setter!
          define_existence_check!
          self
        end

        def define_through_getter!
          assoc = self
          assoc_name = name
          @owner_class.re_define_method(assoc_name) do |reload = false|
            if reload || !instance_variable_defined?("@_#{assoc_name}")
              doc = assoc.criteria(self)
              proxy = doc ? HasOneThrough::Proxy.new(self, doc, assoc) : nil
              set_relation(assoc_name, proxy)
            end
            instance_variable_get("@_#{assoc_name}")
          end
        end

        def define_readonly_setter!
          assoc = self
          @owner_class.re_define_method("#{name}=") do |_object|
            raise Mongoid::Errors::ReadonlyAssociation.new(self.class, assoc)
          end
        end

        def default_primary_key
          PRIMARY_KEY_DEFAULT
        end
      end
    end
  end
end
