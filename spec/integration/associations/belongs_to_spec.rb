# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
require 'support/feature_sandbox'

require_relative '../../mongoid/association/referenced/has_one_models'

describe 'belongs_to associations' do
  context 'referencing top level classes when source class is namespaced' do
    let(:college) { HomCollege.create! }
    let(:child) { HomAccreditation::Child.new(hom_college: college) }

    it 'works' do
      expect(child).to be_valid
    end
  end

  context 'when an anonymous class defines a belongs_to association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        belongs_to :movie
      end
    end

    it 'loads the association correctly' do
      expect { klass }.to_not raise_error
      expect { klass.new.movie }.to_not raise_error
      instance = klass.new
      movie = Movie.new
      instance.movie = movie
      expect(instance.movie).to eq movie
    end
  end

  context 'when the association is polymorphic' do
    def quarantine(example, polymorphic:, aliases:)
      FeatureSandbox.quarantine do
        # Have to eval this, because otherwise we get syntax errors when defining a class
        # inside a method.
        #
        # I know the scissors are sharp! But I want to run with them anwyay!
        Object.class_eval <<-RUBY
          class SandboxManager; include Mongoid::Document; end
          class SandboxDepartment; include Mongoid::Document; end
        RUBY

        SandboxManager.belongs_to :unit, polymorphic: polymorphic

        SandboxDepartment.identify_as *aliases, resolver: polymorphic
        SandboxDepartment.has_one :sandbox_manager, as: :unit

        example.run
      end
    end

    let(:manager) { SandboxManager.create(unit: department) }
    let(:department) { SandboxDepartment.create }

    context 'when the association uses the default resolver' do
      context 'when there are no aliases given' do
        around(:context) { |example| quarantine(example, polymorphic: true, aliases: []) }

        it 'populates the unit_type with the class name' do
          expect(manager.unit_type).to be == 'SandboxDepartment'
        end

        it 'successfully finds the corresponding unit' do
          expect(manager.reload.unit).to be == department
        end
      end

      context 'when there are multiple aliases given' do
        around(:context) { |example| quarantine(example, polymorphic: true, aliases: %w[ dept sandbox_dept ]) }

        it 'populates the unit_type with the first alias' do
          expect(manager.unit_type).to be == 'dept'
        end

        it 'successfully finds the corresponding unit' do
          expect(manager.reload.unit).to be == department
        end

        it 'successfully finds the corresponding unit when unit_type is a different alias' do
          manager.update unit_type: 'sandbox_dept'
          manager.reload

          expect(manager.reload.unit_type).to be == 'sandbox_dept'
          expect(manager.unit).to be == department
        end
      end
    end

    context 'when the association uses a registered resolver' do
      around(:context) do |example|
        Mongoid::ModelResolver.register_resolver Mongoid::ModelResolver.new, :sandbox
        quarantine(example, polymorphic: :sandbox, aliases: %w[ dept sandbox_dept ])
      end

      it 'does not include the aliases in the default resolver' do
        expect(Mongoid::ModelResolver.instance.keys_for(SandboxDepartment.new)).not_to include('dept')
      end

      it 'populates the unit_type with the first alias' do
        expect(manager.unit_type).to be == 'dept'
      end

      it 'successfully finds the corresponding unit' do
        expect(manager.reload.unit).to be == department
      end

      it 'successfully finds the corresponding unit when unit_type is a different alias' do
        manager.update unit_type: 'sandbox_dept'
        manager.reload

        expect(manager.reload.unit_type).to be == 'sandbox_dept'
        expect(manager.unit).to be == department
      end
    end

    context 'when the association uses an unregistered resolver' do
      around(:context) do |example|
        quarantine(example, polymorphic: Mongoid::ModelResolver.new, aliases: %w[ dept sandbox_dept ])
      end

      it 'does not include the aliases in the default resolver' do
        expect(Mongoid::ModelResolver.instance.keys_for(SandboxDepartment.new)).not_to include('dept')
      end

      it 'populates the unit_type with the first alias' do
        expect(manager.unit_type).to be == 'dept'
      end

      it 'successfully finds the corresponding unit' do
        expect(manager.reload.unit).to be == department
      end

      it 'successfully finds the corresponding unit when unit_type is a different alias' do
        manager.update unit_type: 'sandbox_dept'
        manager.reload

        expect(manager.reload.unit_type).to be == 'sandbox_dept'
        expect(manager.unit).to be == department
      end
    end
  end
end
