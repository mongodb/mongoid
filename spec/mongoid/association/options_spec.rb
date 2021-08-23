# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Options do

  STORES_FOREIGN_KEY =
    [
      Mongoid::Association::Referenced::HasAndBelongsToMany,
      Mongoid::Association::Referenced::BelongsTo
    ]

  [
    Mongoid::Association::Embedded::EmbeddedIn,
    Mongoid::Association::Embedded::EmbedsMany,
    Mongoid::Association::Embedded::EmbedsOne,
    Mongoid::Association::Referenced::BelongsTo,
    Mongoid::Association::Referenced::HasMany,
    Mongoid::Association::Referenced::HasOne,
    Mongoid::Association::Referenced::HasAndBelongsToMany
  ].each do |association_class|

    context "when the association type is #{association_class}" do

      let(:class_left) do
        class ClassLeft; include Mongoid::Document; end
        ClassLeft
      end

      let(:class_right) do
        class ClassRight; include Mongoid::Document; end
        ClassRight
      end

      let(:association) do
        association_class.new(class_left, :name, options)
      end

      let(:options) do
        {}
      end

      describe 'the :as option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:as) do

          context 'when :as is in the options' do

            let(:options) do
              {
                  as: :nameable
              }
            end

            it 'returns the :as value' do
              expect(association.as).to eq(:nameable)
            end
          end

          context 'when :as is not in the options' do

            it 'returns nil' do
              expect(association.as).to be_nil
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:as) do

          it 'returns nil' do
            expect(association.as).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  as: :nameable
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#autobuilding?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:autobuild) do

          context 'when :autobuild is in the options' do

            context 'when :autobuild is true' do

              let(:options) do
                {
                    autobuild: true
                }
              end

              it 'returns true' do
                expect(association.autobuilding?).to be(true)
              end
            end

            context 'when :autobuild is false' do

              let(:options) do
                {
                    autobuild: false
                }
              end

              it 'returns false' do
                expect(association.autobuilding?).to be(false)
              end
            end

            context 'when :autobuild is nil' do

              let(:options) do
                {
                    autobuild: nil
                }
              end

              it 'returns false' do
                expect(association.autobuilding?).to be(false)
              end
            end
          end

          context 'when :autobuild is not in the options' do

            it 'returns false' do
              expect(association.autobuilding?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:autobuild) do

          it 'returns false' do
            expect(association.autobuilding?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  autobuild: false
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#autosave?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:autosave) do

          context 'when :autosave is in the options' do

            context 'when :autosave is true' do

              let(:options) do
                {
                    autosave: true
                }
              end

              it 'returns true' do
                expect(association.autosave?).to be(true)
              end
            end

            context 'when :autosave is false' do

              let(:options) do
                {
                    autosave: false
                }
              end

              it 'returns false' do
                expect(association.autosave?).to be(false)
              end
            end

            context 'when :autosave is nil' do

              let(:options) do
                {
                    autosave: nil
                }
              end

              it 'returns false' do
                expect(association.autosave?).to be(false)
              end
            end
          end

          context 'when :autosave is not in the options' do

            it 'returns false' do
              expect(association.autosave?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:autosave) do

          it 'returns false' do
            expect(association.autosave?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  autosave: false
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :dependent option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:dependent) do

          context 'when :dependent is in the options' do

            let(:options) do
              {
                  dependent: :delete_all
              }
            end

            it 'returns the :dependent value' do
              expect(association.dependent).to eq(options[:dependent])
            end
          end

          context 'when :dependent is not in the options' do

            it 'returns nil' do
              expect(association.dependent).to be_nil
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:dependent) do

          it 'returns nil' do
            expect(association.dependent).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  dependent: :delete_all
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :foreign_key option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:foreign_key) do

          context 'when the :foreign_key option is specified' do

            let(:options) do
              {
                  foreign_key: :some_field
              }
            end

            it 'returns the foreign_key as a String' do
              expect(association.foreign_key).to eq(options[:foreign_key].to_s)
            end
          end

          context 'when the association stores the foreign key', if: association_class::VALID_OPTIONS.include?(:foreign_key) &&
                                                                     STORES_FOREIGN_KEY.include?(association_class) do

            context 'when :foreign_key option is not specified' do

              it 'returns the name followed by the foreign_key_suffix' do
                expect(association.foreign_key).to eq("name#{association.class::FOREIGN_KEY_SUFFIX}")
              end
            end
          end

          context 'when the association does not store the foreign key', if: association_class::VALID_OPTIONS.include?(:foreign_key) &&
                                                                             !STORES_FOREIGN_KEY.include?(association_class) do

            context 'when :foreign_key option is not specified' do

              before do
                allow(association).to receive(:inverse).and_return(:other)
              end

              it 'returns the inverse name followed by the foreign_key_suffix' do
                expect(association.foreign_key).to eq("other#{association.class::FOREIGN_KEY_SUFFIX}")
              end
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:foreign_key) do

          it 'returns nil' do
            expect(association.dependent).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  foreign_key: :some_field
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :primary_key option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:primary_key) do

          context 'when the option is specified' do

            let(:options) do
              {
                  primary_key: :other_id
              }
            end

            it 'returns the primary_key from the options as a String' do
              expect(association.primary_key).to eq(options[:primary_key].to_s)
            end
          end

          context 'when the option is not specified' do

            it 'returns the default primary key' do
              expect(association.primary_key).to eq(Mongoid::Association::Relatable::PRIMARY_KEY_DEFAULT)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:primary_key) do

          it 'returns nil' do
            expect(association.primary_key).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  primary_key: :other_id
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :after_add option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:after_add) do

          context 'when the :after_add option is specified' do

            let(:options) do
              {
                  after_add: :method_name
              }
            end

            it 'retrieves the after_add method name from the association' do
              expect(association.get_callbacks(:after_add)).to eq(Array(options[:after_add]))
            end
          end

          context 'when the :after_add option is not specified' do

            it 'returns nil' do
              expect(association.get_callbacks(:after_add)).to be_empty
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:after_add) do


          it 'returns nil' do
            expect(association.get_callbacks(:after_add)).to be_empty
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  after_add: :method_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :after_remove option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:after_remove) do

          context 'when the :after_remove option is specified' do

            let(:options) do
              {
                  after_remove: :method_name
              }
            end

            it 'retrieves the after_remove method name from the association' do
              expect(association.get_callbacks(:after_remove)).to eq(Array(options[:after_remove]))
            end
          end

          context 'when the :after_remove option is not specified' do

            it 'returns nil' do
              expect(association.get_callbacks(:after_remove)).to be_empty
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:after_remove) do


          it 'returns nil' do
            expect(association.get_callbacks(:after_remove)).to be_empty
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  after_remove: :method_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :before_add option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:before_add) do

          context 'when the :before_add option is specified' do

            let(:options) do
              {
                  before_add: :method_name
              }
            end

            it 'retrieves the before_add method name from the association' do
              expect(association.get_callbacks(:before_add)).to eq(Array(options[:before_add]))
            end
          end

          context 'when the :before_add option is not specified' do

            it 'returns nil' do
              expect(association.get_callbacks(:before_add)).to be_empty
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:before_add) do


          it 'returns nil' do
            expect(association.get_callbacks(:before_add)).to be_empty
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  before_add: :method_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :before_remove option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:before_remove) do

          context 'when the :before_remove option is specified' do

            let(:options) do
              {
                  before_remove: :method_name
              }
            end

            it 'retrieves the before_remove method name from the association' do
              expect(association.get_callbacks(:before_remove)).to eq(Array(options[:before_remove]))
            end
          end

          context 'when the :before_remove option is not specified' do

            it 'returns nil' do
              expect(association.get_callbacks(:before_remove)).to be_empty
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:before_remove) do


          it 'returns nil' do
            expect(association.get_callbacks(:before_remove)).to be_empty
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  before_remove: :method_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end


      describe '#indexed?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:index) do

          context 'when :index is in the options' do

            context 'when :index is true' do

              let(:options) do
                {
                    index: true
                }
              end

              it 'returns true' do
                expect(association.indexed?).to be(true)
              end
            end

            context 'when :index is false' do

              let(:options) do
                {
                    index: false
                }
              end

              it 'returns false' do
                expect(association.indexed?).to be(false)
              end
            end

            context 'when :index is nil' do

              let(:options) do
                {
                    index: nil
                }
              end

              it 'returns false' do
                expect(association.indexed?).to be(false)
              end
            end
          end

          context 'when :index is not in the options' do

            it 'returns false' do
              expect(association.indexed?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:index) do

          it 'returns false' do
            expect(association.indexed?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  index: true
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :order option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:order) do

          context 'when :order is in the options' do

            let(:options) do
              {
                  order: :rating.desc
              }
            end

            it 'returns a Mongoid::Criteria::Queryable::Key' do
              expect(association.order).to be_a(Mongoid::Criteria::Queryable::Key)
            end
          end

          context 'when :order is not in the options' do

            it 'returns nil' do
              expect(association.order).to be_nil
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:order) do

          it 'returns nil' do
            expect(association.order).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  order: :rating.desc
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#polymorphic' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:polymorphic) do

          context 'when :polymorphic is in the options' do

            context 'when :polymorphic is true' do

              let(:options) do
                {
                    polymorphic: true
                }
              end

              it 'returns true' do
                expect(association.polymorphic?).to be(true)
              end
            end

            context 'when :polymorphic is false' do

              let(:options) do
                {
                    polymorphic: false
                }
              end

              it 'returns false' do
                expect(association.polymorphic?).to be(false)
              end
            end

            context 'when :polymorphic is nil' do

              let(:options) do
                {
                    polymorphic: nil
                }
              end

              it 'returns false' do
                expect(association.polymorphic?).to be(false)
              end
            end
          end

          context 'when :polymorphic is not in the options' do

            it 'returns false' do
              expect(association.polymorphic?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:polymorphic) do

          it 'returns false' do
            expect(association.polymorphic?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  polymorphic: true
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#cascading_callbacks?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:cascade_callbacks) do

          context 'when :cascade_callbacks is in the options' do

            context 'when :cascade_callbacks is true' do

              let(:options) do
                {
                    cascade_callbacks: true
                }
              end

              it 'returns true' do
                expect(association.cascading_callbacks?).to be(true)
              end
            end

            context 'when :cascade_callbacks is false' do

              let(:options) do
                {
                    cascade_callbacks: false
                }
              end

              it 'returns false' do
                expect(association.cascading_callbacks?).to be(false)
              end
            end

            context 'when :cascade_callbacks is nil' do

              let(:options) do
                {
                    cascade_callbacks: nil
                }
              end

              it 'returns false' do
                expect(association.cascading_callbacks?).to be(false)
              end
            end
          end

          context 'when :cascade_callbacks is not in the options' do

            it 'returns false' do
              expect(association.cascading_callbacks?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:cascade_callbacks) do

          it 'returns false' do
            expect(association.cascading_callbacks?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  cascade_callbacks: true
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#cyclic?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:cyclic) do

          context 'when :cyclic is in the options' do

            context 'when :cyclic is true' do

              let(:options) do
                {
                    cyclic: true
                }
              end

              it 'returns true' do
                expect(association.cyclic?).to be(true)
              end
            end

            context 'when :cyclic is false' do

              let(:options) do
                {
                    cyclic: false
                }
              end

              it 'returns false' do
                expect(association.cyclic?).to be(false)
              end
            end

            context 'when :cyclic is nil' do

              let(:options) do
                {
                    cyclic: nil
                }
              end

              it 'returns false' do
                expect(association.cyclic?).to be(false)
              end
            end
          end

          context 'when :cyclic is not in the options' do

            it 'returns false' do
              expect(association.cyclic?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:cyclic) do

          it 'returns false' do
            expect(association.cyclic?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  cyclic: true
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :store_as option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:store_as) do

          context 'when :store_as is in the options' do

            let(:options) do
              {
                  store_as: :another_name
              }
            end

            it 'returns the :store_as value' do
              expect(association.store_as).to eq(options[:store_as].to_s)
            end
          end

          context 'when :store_as is not in the options' do

            it 'returns the name as a string' do
              expect(association.store_as).to eq("name")
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:store_as) do

          it 'returns nil' do
            expect(association.store_as).to be_nil
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  store_as: :another_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe 'the :class_name option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:class_name) do

          context 'when :class_name is in the options' do

            let(:options) do
              {
                  class_name: :a_class
              }
            end

            it 'returns the :class_name value' do
              expect(association.class_name).to eq(:a_class)
            end
          end

          context 'when :class_name is not in the options' do

            it 'returns the name deduced from the association name' do
              expect(association.class_name).to eq(ActiveSupport::Inflector.classify(:name))
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:class_name) do

          it 'returns the name deduced from the association name' do
            expect(association.class_name).to eq(ActiveSupport::Inflector.classify(:name))
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  class_name: :a_class
              }
            end

            it 'should support the option' do
              fail('All association types should support this option')
            end
          end
        end
      end

      describe '#counter_cached?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:counter_cache) do

          context 'when :counter_cache is in the options' do

            context 'when :counter_cache is true' do

              let(:options) do
                {
                    counter_cache: true
                }
              end

              it 'returns true' do
                expect(association.counter_cached?).to be(true)
              end
            end

            context 'when :counter_cache is false' do

              let(:options) do
                {
                    counter_cache: false
                }
              end

              it 'returns false' do
                expect(association.counter_cached?).to be(false)
              end
            end

            context 'when :counter_cache is nil' do

              let(:options) do
                {
                    counter_cache: nil
                }
              end

              it 'returns false' do
                expect(association.counter_cached?).to be(false)
              end
            end
          end

          context 'when :counter_cache is not in the options' do

            it 'returns false' do
              expect(association.counter_cached?).to be(false)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:counter_cache) do

          it 'returns false' do
            expect(association.counter_cached?).to be(false)
          end

          context 'when the option is provided' do

            let(:options) do
              {
                  counter_cache: :column_name
              }
            end

            it 'raises a Mongoid::Errors::InvalidRelationOption error' do
              expect {
                association
              }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
            end
          end
        end
      end

      describe '#extension' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:extend) do

          context 'when a block is passed' do

            let!(:association) do
              association_class.new(class_left, :name, options) do; end
            end

            after do
              Object.send(:remove_const, :ClassLeft)
            end

            it 'defines an extension module' do
              expect(ClassLeft::ClassLeftNameRelationExtension).to be_a(Module)
            end

            it 'returns the extension' do
              expect(association.extension).to eq(ClassLeft::ClassLeftNameRelationExtension)
            end
          end

          context 'when a module name is passed' do

            before do
              class ClassLeft; end
              module ClassLeft::Handle; end
            end

            let(:options) do
              {
                  extend: ClassLeft::Handle
              }
            end

            let!(:association) do
              association_class.new(class_left, :name, options)
            end

            it 'returns the extension' do
              expect(association.extension).to eq(ClassLeft::Handle)
            end
          end

          context 'when a block is not passed' do

            it 'does not define an extension module' do
              expect(defined?(ClassLeft::ClassLeftNameRelationExtension)).to be_nil
            end

            it 'returns nil' do
              expect(association.extension).to be_nil
            end
          end


        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:extend) do

          it 'should support the option' do
            fail('All association types should support this option')
          end
        end
      end

      describe 'the :inverse_of option' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:inverse_of) do

          context 'when :inverse_of is in the options' do

            let(:options) do
              {
                  inverse_of: :inverse_name
              }
            end

            it 'returns the :inverse_of value' do
              expect(association.inverse_of).to eq(:inverse_name)
            end
          end

          context 'when :inverse_of is not in the options' do

            it 'returns nil' do
              expect(association.inverse_of).to be_nil
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:inverse_of) do

          it 'returns nil' do
            expect(association.inverse_of).to be_nil
          end


          context 'when the option is provided' do

            let(:options) do
              {
                  inverse_of: :inverse_name
              }
            end

            it 'should support the option' do
              fail('All association types should support this option')
            end
          end
        end
      end

      describe '#validate?' do

        context 'when the option is supported by the association type', if: association_class::VALID_OPTIONS.include?(:validate) do

          context 'when :validate is in the options' do

            context 'when :validate is true' do

              let(:options) do
                {
                    validate: true
                }
              end

              it 'returns true' do
                expect(association.send(:validate?)).to be(true)
              end
            end

            context 'when :validate is false' do

              let(:options) do
                {
                    validate: false
                }
              end

              it 'returns false' do
                expect(association.send(:validate?)).to be(false)
              end
            end

            context 'when :validate is nil' do

              let(:options) do
                {
                    validate: nil
                }
              end

              it 'returns the validation default' do
                expect(association.send(:validate?)).to be(association.validation_default)
              end
            end
          end

          context 'when :validate is not in the options' do

            it 'returns the validation default' do
              expect(association.send(:validate?)).to be(association.validation_default)
            end
          end
        end

        context 'when the option is not supported by the association type', if: !association_class::VALID_OPTIONS.include?(:validate) do

          it 'returns false' do
            expect(association.send(:validate?)).to be(false)
          end


          context 'when the option is provided' do

            let(:options) do
              {
                  validate: true
              }
            end

            it 'should support the option' do
              fail('All association types should support this option')
            end
          end
        end
      end
    end
  end
end
