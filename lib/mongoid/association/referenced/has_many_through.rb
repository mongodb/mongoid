# frozen_string_literal: true

require 'mongoid/association/referenced/has_many_through/proxy'
require 'mongoid/association/referenced/has_many_through/eager'

module Mongoid
  module Association
    module Referenced
      # Metadata class for has_many :through associations.
      class HasManyThrough
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

        # Through associations never store a foreign key on the owner document.
        #
        # @return [ false ]
        def stores_foreign_key?
          false
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
            source_name = (@options[:source] || name.to_s.singularize).to_s
            through_association.klass.relations[source_name] ||
              raise(
                Errors::InvalidRelationOption.new(
                  @owner_class, name, :source, source_name
                )
              )
          end
        end

        # Return a Criteria scoped to the target documents reachable from base
        # via the through association. Performs two queries: one against the
        # intermediate collection, one against the source collection.
        #
        # @param [ Document ] base The owner document.
        #
        # @return [ Mongoid::Criteria ]
        def criteria(base)
          through_crit = through_association.criteria(base)

          if source_association.stores_foreign_key?
            # FK is on the intermediate (e.g. appointment.patient_id -> belongs_to :patient)
            target_pk = source_association.primary_key # '_id' on Patient
            source_fk = source_association.foreign_key # 'patient_id' on Appointment
            source_association.klass.where(
              target_pk => { '$in' => through_crit.pluck(source_fk) }
            )
          else
            # FK is on the source (e.g. reader.book_id -> has_many :readers on Book)
            through_pk = through_association.primary_key # '_id' on Book
            source_fk  = source_association.foreign_key # 'book_id' on Reader
            source_association.klass.where(
              source_fk => { '$in' => through_crit.pluck(through_pk) }
            )
          end
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
          define_through_ids_getter!
          define_readonly_setter!
          define_existence_check!
          self
        end

        def define_through_getter!
          assoc = self
          assoc_name = name
          @owner_class.re_define_method(assoc_name) do |reload = false|
            if reload || !instance_variable_defined?("@_#{assoc_name}")
              set_relation(assoc_name, HasManyThrough::Proxy.new(self, assoc))
            end
            instance_variable_get("@_#{assoc_name}")
          end
        end

        def define_through_ids_getter!
          assoc_name = name
          ids_method = :"#{assoc_name.to_s.singularize}_ids"
          @owner_class.re_define_method(ids_method) do
            send(assoc_name).pluck(:_id)
          end
        end

        def define_readonly_setter!
          assoc = self
          @owner_class.re_define_method(:"#{name}=") do |_object|
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
