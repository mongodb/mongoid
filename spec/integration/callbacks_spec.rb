# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'
require_relative './callbacks_models'

describe 'callbacks integration tests' do
  context 'when modifying attributes in a callback' do

    context 'when creating top-level document' do
      context 'top level document' do
        let(:instance) do
          Galaxy.create!
        end

        it 'writes the attribute value into the model' do
          instance.age.should == 100_000
        end

        it 'persists the attribute value' do
          Galaxy.find(instance.id).age.should == 100_000
        end
      end

      context 'embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.age.should == 42_000
          end

          it 'persists the attribute value' do
            Galaxy.find(instance.id).stars.first.age.should == 42_000
          end
        end

        context 'set as a document instance' do
          let(:instance) do
            Galaxy.create!(stars: [Star.new])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          let(:instance) do
            Galaxy.create!(stars: [{}])
          end

          include_examples 'persists the attribute value'
        end
      end

      context 'nested embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.planets.first.age.should == 2_000
          end

          it 'persists the attribute value' do
            Galaxy.find(instance.id).stars.first.planets.first.age.should == 2_000
          end
        end

        context 'set as a document instance' do
          let(:instance) do
            Galaxy.create!(stars: [Star.new(
              planets: [Planet.new],
            )])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          let(:instance) do
            Galaxy.create!(stars: [
              planets: [{}],
            ])
          end

          include_examples 'persists the attribute value'
        end
      end
    end

    context 'when updating top-level document via #save' do
      let!(:instance) do
        Galaxy.create!
      end

      context 'embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.age.should == 42_000
          end

          it 'persists the attribute value' do
            Galaxy.find(instance.id).stars.first.age.should == 42_000
          end
        end

        context 'set as a document instance' do
          before do
            instance.stars = [Star.new]
            instance.save!
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.stars = [{}]
            instance.save!
          end

          include_examples 'persists the attribute value'
        end
      end

      context 'nested embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.planets.first.age.should == 2_000
          end

          it 'persists the attribute value' do
            Galaxy.find(instance.id).stars.first.planets.first.age.should == 2_000
          end
        end

        context 'set as a document instance' do
          before do
            instance.stars = [Star.new(planets: [Planet.new])]
            instance.save!
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.stars = [planets: [{}]]
            instance.save!
          end

          include_examples 'persists the attribute value'
        end
      end
    end

    context 'when updating top-level document via #update_attributes' do
      let!(:instance) do
        Galaxy.create!
      end

      context 'embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.age.should == 42_000
          end

          it 'persists the attribute value' do
            Galaxy.find(instance.id).stars.first.age.should == 42_000
          end
        end

        context 'set as a document instance' do
          before do
            instance.update_attributes(stars: [Star.new])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes(stars: [{}])
          end

          include_examples 'persists the attribute value'
        end
      end

      context 'nested embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.stars.first.planets.first.age.should == 2_000
          end

          it 'persists the attribute value' do
            pending 'MONGOID-4476'

            Galaxy.find(instance.id).stars.first.planets.first.age.should == 2_000
          end
        end

        context 'set as a document instance' do
          before do
            instance.update_attributes(stars: [Star.new(planets: [Planet.new])])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes(stars: [planets: [{}]])
          end

          include_examples 'persists the attribute value'
        end
      end
    end
  end
end
