# frozen_string_literal: true

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

    context 'when updating top-level document via #update_attributes!' do
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
            instance.update_attributes!(stars: [Star.new])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes!(stars: [{}])
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
            instance.update_attributes!(stars: [Star.new(planets: [Planet.new])])
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes!(stars: [planets: [{}]])
          end

          include_examples 'persists the attribute value'
        end
      end
    end

    context 'when updating top-level embeds_one document via #update_attributes!' do
      let!(:instance) do
        Country.create!
      end

      context 'embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.president.age.should == 79
          end

          it 'persists the attribute value' do
            Country.find(instance.id).president.age.should == 79
          end
        end

        context 'set as a document instance' do
          before do
            instance.update_attributes!(president: President.new)
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes!(president: { name: "Abraham Lincoln" })
          end

          include_examples 'persists the attribute value'
        end
      end

      context 'nested embedded document' do
        shared_examples 'persists the attribute value' do
          it 'writes the attribute value into the model' do
            instance.president.first_spouse.age.should == 70
          end

          it 'persists the attribute value' do
            Country.find(instance.id).president.first_spouse.age.should == 70
          end
        end

        context 'set as a document instance' do
          before do
            instance.update_attributes!(president: President.new(first_spouse: FirstSpouse.new))
          end

          include_examples 'persists the attribute value'
        end

        context 'set as attributes on parent' do
          before do
            instance.update_attributes!(president: { first_spouse: { name: "Mary Todd Lincoln" } })
          end

          include_examples 'persists the attribute value'
        end
      end
    end
  end

  context 'attribute_was value in after_save callback' do
    let!(:obj) { Emission.create!(frequency: 1) }

    it 'is set to the new value' do
      obj.frequency = 2
      obj.save!

      obj.previous.should == 2
    end
  end

  context 'atomic_selector in after_save callback' do
    let(:name) do
      'Alice'
    end

    let(:new_name) do
      'Bob'
    end

    class CBIntSpecProfile
      include Mongoid::Document
      field :name, type: String
      shard_key :name

      attr_reader :atomic_selector_in_after_save

      after_save do |document|
        @atomic_selector_in_after_save = document.atomic_selector
      end
    end

    it 'has updated attributes' do
      profile = CBIntSpecProfile.create!(name: name)
      profile.name = new_name
      profile.save!
      expect(
        profile.atomic_selector_in_after_save['name']
      ).to eq(new_name)
    end
  end

  context "When touching an embedded document" do
    let(:planet) { Planet.new }
    let(:star) { Star.new }
    let(:galaxy) { Galaxy.create! }

    before do
      star.planets << planet
      galaxy.stars << star
    end

    it "the parent document touch callback gets called before the child" do
      planet.touch
      expect(galaxy.was_touched).to be true
      expect(star.was_touched_after_parent).to be true
      expect(planet.was_touched_after_parent).to be true
    end
  end

  context "when reloading has_and_belongs_to_many after_save and after_remove callbacks" do

    let(:architect) { Architect.create }

    let(:b1) { Building.create }

    let(:b2) { Building.create }

    let(:b3) { Building.create }

    it "counts added/removed buildings correctly" do
      architect.buildings << b1
      expect(architect.after_add_num_buildings).to eq(1)

      architect.reload
      architect.buildings << b2
      expect(architect.after_add_num_buildings).to eq(2)

      architect.reload
      architect.buildings << b3
      expect(architect.after_add_num_buildings).to eq(3)

      architect.reload
      architect.buildings.delete(b3)
      expect(architect.after_remove_num_buildings).to eq(2)
    end
  end

  context '_previously was methods in after_save callback' do
    let(:title) do
      "Title"
    end

    let(:updated_title) do
      "Updated title"
    end

    let(:age) do
      10
    end

    it do
      class PreviouslyWasPerson
        include Mongoid::Document

        field :title, type: String
        field :age, type: Integer

        attr_reader :after_save_vals

        set_callback :save, :after do |doc|
          @after_save_vals ||= []
          @after_save_vals << [doc.title_previously_was, doc.age_previously_was]
        end
      end

      person = PreviouslyWasPerson.create!(title: title, age: age)
      person.title = updated_title
      person.save!
      expect(person.after_save_vals).to eq([
        # Field values are nil before create
        [nil, nil],
        [title, age]
        ])
    end
  end

  context 'previously_new_record? in after_save' do
    it do
      class PreviouslyNewRecordPerson
        include Mongoid::Document

        field :title, type: String
        field :age, type: Integer

        attr_reader :previously_new_record_value

        set_callback :save, :after do |doc|
          @previously_new_record_value = doc.previously_new_record?
        end
      end

      person = PreviouslyNewRecordPerson.create!(title: "title", age: 55)
      expect(person.previously_new_record_value).to be_truthy
      person.title = "New title"
      person.save!
      expect(person.previously_new_record_value).to be_falsey
    end
  end

  context 'previously_persisted? in after_destroy' do
    it do
      class PreviouslyPersistedPerson
        include Mongoid::Document

        field :title, type: String
        field :age, type: Integer

        attr_reader :previously_persisted_value

        set_callback :destroy, :after do |doc|
          @previously_persisted_value = doc.previously_persisted?
        end
      end

      unsaved_person = PreviouslyPersistedPerson.new(title: "title", age: 55)
      unsaved_person.destroy
      expect(unsaved_person.previously_persisted_value).to be_falsey

      saved_person = PreviouslyPersistedPerson.create(title: "title", age: 55)
      saved_person.destroy
      expect(saved_person.previously_persisted_value).to be_truthy
    end
  end

  context 'saved_change_to_attribute, attribute_before_last_save, will_save_change_to_attribute' do
    class TestSCTAAndABLSInCallbacks
      include Mongoid::Document

      field :name, type: String
      field :age, type: Integer

      set_callback :save, :before do |doc|
        [:name, :age].each do |attr|
          saved_change_to_attribute_values_before[attr] += [saved_change_to_attribute(attr)]
          attribute_before_last_save_values_before[attr] += [attribute_before_last_save(attr)]
          will_save_change_to_attribute_values_before[attr] += [will_save_change_to_attribute?(attr)]
        end
      end

      set_callback :save, :after do |doc|
        [:name, :age].each do |attr|
          saved_change_to_attribute_values_after[attr] += [saved_change_to_attribute(attr)]
          saved_change_to_attribute_q_values_after[attr] += [saved_change_to_attribute?(attr)]
          attribute_before_last_save_values_after[attr] += [attribute_before_last_save(attr)]
        end
      end

      def saved_change_to_attribute_values_before
        @saved_change_to_attribute_values_before ||= Hash.new do
          []
        end
      end

      def attribute_before_last_save_values_before
        @attribute_before_last_save_values_before ||= Hash.new do
          []
        end
      end

      def saved_change_to_attribute_values_after
        @saved_change_to_attribute_values_after ||= Hash.new do
          []
        end
      end

      def saved_change_to_attribute_q_values_after
        @saved_change_to_attribute_q_values_after ||= Hash.new do
          []
        end
      end

      def attribute_before_last_save_values_after
        @attribute_before_last_save_values_after ||= Hash.new do
          []
        end
      end

      def will_save_change_to_attribute_values_before
        @will_save_change_to_attribute_values_before ||= Hash.new do
          []
        end
      end
    end

    it 'reproduces ActiveRecord::AttributeMethods::Dirty behavior' do
      subject = TestSCTAAndABLSInCallbacks.new(name: 'Name 1')
      subject.save!
      subject.age = 18
      subject.save!
      subject.name = 'Name 2'
      subject.save!

      expect(subject.saved_change_to_attribute_values_before).to eq(
        {
          :name => [nil, [nil, "Name 1"], nil],
          :age => [nil, nil, [nil, 18]],
        }
      )
      expect(subject.saved_change_to_attribute_values_after).to eq(
        {
          :name => [[nil, "Name 1"], nil, ["Name 1", "Name 2"]],
          :age => [nil, [nil, 18], nil],
        }
      )
      expect(subject.saved_change_to_attribute_q_values_after).to eq(
        {
          :name => [true, false, true],
          :age => [false, true, false],
        }
      )
      expect(subject.attribute_before_last_save_values_before).to eq(
        {
          :name => [nil, nil, "Name 1"],
          :age => [nil, nil, nil]
        }
      )
      expect(subject.attribute_before_last_save_values_after).to eq(
        {
          :name => [nil, "Name 1", "Name 1"],
          :age => [nil, nil, 18]
        }
      )
      expect(subject.will_save_change_to_attribute_values_before).to eq(
        {
          :name => [true, false, true],
          :age => [false, true, false]
        }
      )
    end
  end

  context 'nested embedded documents' do
    config_override :prevent_multiple_calls_of_embedded_callbacks, true

    let(:logger) { Array.new }

    let(:root) do
      Root.new(
        embedded_once: [
          EmbeddedOnce.new(
            embedded_twice: [EmbeddedTwice.new]
          )
        ]
      )
    end

    before(:each) do
      root.logger = logger
      root.embedded_once.first.logger = logger
      root.embedded_once.first.embedded_twice.first.logger = logger
    end

    it 'runs callbacks in the correct order' do
      root.save!
      expect(logger).to eq(%i[embedded_twice embedded_once root])
    end
  end
end
