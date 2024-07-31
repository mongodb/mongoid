# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'
require 'support/feature_sandbox'

require_relative '../../mongoid/association/referenced/has_one_models'

def quarantine(context, polymorphic:, dept_aliases:, team_aliases:)
  state = {}

  context.before(:context) do
    state[:quarantine] = FeatureSandbox.start_quarantine

    # Have to eval this, because otherwise we get syntax errors when defining a class
    # inside a method.
    #
    # I know the scissors are sharp! But I want to run with them anwyay!
    Object.class_eval <<-RUBY
      class SandboxManager; include Mongoid::Document; end
      class SandboxDepartment; include Mongoid::Document; end
      class SandboxTeam; include Mongoid::Document; end
    RUBY

    SandboxManager.belongs_to :unit, polymorphic: polymorphic

    SandboxDepartment.identify_as *dept_aliases, resolver: polymorphic
    SandboxDepartment.has_many :sandbox_managers, as: :unit

    SandboxTeam.identify_as *team_aliases, resolver: polymorphic
    SandboxTeam.has_one :sandbox_manager, as: :unit
  end

  context.after(:context) do
    FeatureSandbox.end_quarantine(state[:quarantine])
  end
end

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
    let(:dept_manager) { SandboxManager.create(unit: department) }
    let(:team_manager) { SandboxManager.create(unit: team) }
    let(:department) { SandboxDepartment.create }
    let(:team) { SandboxTeam.create }

    shared_context 'it finds the associated records' do
      it 'successfully finds the manager\'s unit' do
        expect(dept_manager.reload.unit).to be == department
        expect(team_manager.reload.unit).to be == team
      end

      it 'successfully finds the unit\'s manager' do
        dept_manager; team_manager # make sure these are created first...

        expect(department.reload.sandbox_managers).to be == [ dept_manager ]
        expect(team.reload.sandbox_manager).to be == team_manager
      end
    end

    shared_context 'it searches for alternative aliases' do
      it 'successfully finds the corresponding unit when unit_type is a different alias' do
        dept_manager.update unit_type: 'sandbox_dept'
        dept_manager.reload

        team_manager.update unit_type: 'group'
        team_manager.reload

        expect(dept_manager.reload.unit_type).to be == 'sandbox_dept'
        expect(dept_manager.unit).to be == department

        expect(team_manager.reload.unit_type).to be == 'group'
        expect(team_manager.unit).to be == team
      end
    end

    context 'when the association uses the default resolver' do
      context 'when there are no aliases given' do
        quarantine(self, polymorphic: true, dept_aliases: [], team_aliases: [])

        it 'populates the unit_type with the class name' do
          expect(dept_manager.unit_type).to be == 'SandboxDepartment'
          expect(team_manager.unit_type).to be == 'SandboxTeam'
        end

        it_behaves_like 'it finds the associated records'
      end

      context 'when there are multiple aliases given' do
        quarantine(self, polymorphic: true, dept_aliases: %w[ dept sandbox_dept ], team_aliases: %w[ team group ])

        it 'populates the unit_type with the first alias' do
          expect(dept_manager.unit_type).to be == 'dept'
          expect(team_manager.unit_type).to be == 'team'
        end

        it_behaves_like 'it finds the associated records'
        it_behaves_like 'it searches for alternative aliases'
      end
    end

    context 'when the association uses a registered resolver' do
      before(:context) { Mongoid::ModelResolver.register_resolver Mongoid::ModelResolver.new, :sandbox }
      quarantine(self, polymorphic: :sandbox, dept_aliases: %w[ dept sandbox_dept ], team_aliases: %w[ team group ])

      it 'does not include the aliases in the default resolver' do
        expect(Mongoid::ModelResolver.instance.keys_for(SandboxDepartment.new)).not_to include('dept')
      end

      it 'populates the unit_type with the first alias' do
        expect(dept_manager.unit_type).to be == 'dept'
        expect(team_manager.unit_type).to be == 'team'
      end

      it_behaves_like 'it finds the associated records'
      it_behaves_like 'it searches for alternative aliases'
    end

    context 'when the association uses an unregistered resolver' do
      quarantine(self, polymorphic: Mongoid::ModelResolver.new,
        dept_aliases: %w[ dept sandbox_dept ],
        team_aliases: %w[ team group ])

      it 'does not include the aliases in the default resolver' do
        expect(Mongoid::ModelResolver.instance.keys_for(SandboxDepartment.new)).not_to include('dept')
      end

      it 'populates the unit_type with the first alias' do
        expect(dept_manager.unit_type).to be == 'dept'
        expect(team_manager.unit_type).to be == 'team'
      end

      it_behaves_like 'it finds the associated records'
      it_behaves_like 'it searches for alternative aliases'
    end
  end
end
