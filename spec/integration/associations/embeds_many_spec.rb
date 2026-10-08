# frozen_string_literal: true

require 'spec_helper'

module EmbedsManySpec
  class Post
    include Mongoid::Document

    field :title, type: String
    embeds_many :comments, class_name: 'EmbedsManySpec::Comment', as: :container
    accepts_nested_attributes_for :comments
  end

  class Comment
    include Mongoid::Document

    field :content, type: String
    validates :content, presence: true
    embedded_in :container, polymorphic: true
    embeds_many :comments, class_name: 'EmbedsManySpec::Comment', as: :container
    accepts_nested_attributes_for :comments
  end
end

module StaleEmbeddedPathSpec
  class Root
    include Mongoid::Document

    embeds_many :items, class_name: 'StaleEmbeddedPathSpec::Item'
    accepts_nested_attributes_for :items, allow_destroy: true
  end

  class Item
    include Mongoid::Document

    field :name, type: String
    field :label, type: String
    embedded_in :root
    embeds_many :leaves, class_name: 'StaleEmbeddedPathSpec::Leaf'
  end

  class Leaf
    include Mongoid::Document

    field :name, type: String
    embedded_in :item
    embeds_many :twigs, class_name: 'StaleEmbeddedPathSpec::Twig'
  end

  class Twig
    include Mongoid::Document

    field :name, type: String
    embedded_in :leaf
  end
end

module MONGOID5364Spec
  class House
    include Mongoid::Document

    embeds_many :rooms, class_name: 'MONGOID5364Spec::Room'
  end

  class Room
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    embeds_many :residents, class_name: 'MONGOID5364Spec::Resident'
    embedded_in :house
  end

  class Resident
    include Mongoid::Document

    field :name, type: String
    embedded_in :room
  end
end

describe 'embeds_many associations' do
  context 'when an embedded sibling is removed after an embedded association is changed' do
    it 'writes a replaced association to the current array position' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a
      b.attributes = { leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'new') ] }
      root.items.delete(a)
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves.map(&:name)).to eq([ 'new' ])
      expect(persisted_c.leaves.map(&:name)).to eq([ 'c1' ])
    end

    it 'writes a replaced association to the current array position when a sibling is destroyed with nested attributes' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a
      b.attributes = { leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'new') ] }
      root.items_attributes = [ { id: a.id, _destroy: '1' } ]
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves.map(&:name)).to eq([ 'new' ])
      expect(persisted_c.leaves.map(&:name)).to eq([ 'c1' ])
    end

    it 'unsets a replaced association at the current array position' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a
      b.attributes = { leaves: [] }
      root.items.delete(a)
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves).to be_empty
      expect(persisted_c.leaves.map(&:name)).to eq([ 'c1' ])
    end

    it 'unsets a removed attribute at the current array position' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a
      b.remove_attribute(:label)
      root.items.delete(a)
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.label).to be_nil
      expect(persisted_c.label).to eq('c-label')
    end

    it 'unsets a nested empty association at its current array position' do
      root = StaleEmbeddedPathSpec::Root.create!(
        items: [
          StaleEmbeddedPathSpec::Item.new(name: 'a'),
          StaleEmbeddedPathSpec::Item.new(
            name: 'b',
            leaves: [
              StaleEmbeddedPathSpec::Leaf.new(
                name: 'b1',
                twigs: [ StaleEmbeddedPathSpec::Twig.new(name: 'b1a') ]
              )
            ]
          ),
          StaleEmbeddedPathSpec::Item.new(
            name: 'c',
            leaves: [
              StaleEmbeddedPathSpec::Leaf.new(
                name: 'c1',
                twigs: [ StaleEmbeddedPathSpec::Twig.new(name: 'c1a') ]
              )
            ]
          )
        ]
      )
      (a, b, *_remaining) = root.items.to_a
      b.leaves.first.attributes = { twigs: [] }
      root.items.delete(a)
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves.first.twigs).to be_empty
      expect(persisted_c.leaves.first.twigs.map(&:name)).to eq([ 'c1a' ])
    end

    it 'preserves push-then-clear behaviour after removing a preceding sibling' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a

      b.leaves.push(StaleEmbeddedPathSpec::Leaf.new(name: 'pushed'))
      root.items.delete(a)
      b.leaves.clear
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves).to be_empty
      expect(persisted_c.leaves.map(&:name)).to eq([ 'c1' ])
    end

    it 'updates the last nested association after removing an earlier sibling as reported in MONGOID-5364' do
      house = MONGOID5364Spec::House.new(rooms: [])
      5.times do |index|
        house.rooms << MONGOID5364Spec::Room.new(residents: [ { name: "resident #{index}" } ])
      end
      house.save!
      house = MONGOID5364Spec::House.find(house.id)

      house.rooms.last.assign_attributes(residents: [ { name: 'the new resident' } ])
      house.rooms[2].destroy
      house.save!

      persisted_house = MONGOID5364Spec::House.find(house.id)

      expect(persisted_house.rooms.size).to eq(4)
      expect(persisted_house.rooms[-2].residents.map(&:name)).to eq([ 'resident 3' ])
      expect(persisted_house.rooms.last.residents.map(&:name)).to eq([ 'the new resident' ])
    end

    it 'replaces a delayed non-empty association with an empty one after a sibling removal' do
      root = root_with_items
      (a, b, *_remaining) = root.items.to_a

      b.attributes = { leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'new') ] }
      root.items.delete(a)
      b.attributes = { leaves: [] }
      root.save!

      persisted_root = StaleEmbeddedPathSpec::Root.find(root.id)
      persisted_b, persisted_c = persisted_root.items.to_a

      expect(persisted_b.leaves).to be_empty
      expect(persisted_c.leaves.map(&:name)).to eq([ 'c1' ])
    end

    def root_with_items
      StaleEmbeddedPathSpec::Root.create!(
        items: [
          StaleEmbeddedPathSpec::Item.new(
            name: 'a', label: 'a-label', leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'a1') ]
          ),
          StaleEmbeddedPathSpec::Item.new(
            name: 'b', label: 'b-label', leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'b1') ]
          ),
          StaleEmbeddedPathSpec::Item.new(
            name: 'c', label: 'c-label', leaves: [ StaleEmbeddedPathSpec::Leaf.new(name: 'c1') ]
          )
        ]
      )
    end
  end

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:canvas) do
        Canvas.create!(shapes: [ Shape.new ])
      end

      let!(:shape) { canvas.shapes.first }

      it 'does not destroy the dependent object' do
        canvas.shapes = [ shape ]
        canvas.save!
        canvas.reload
        canvas.shapes.should eq [ shape ]
      end
    end
  end

  context 'clearing association when parent is not saved' do
    let!(:parent) { Canvas.create!(shapes: [ Shape.new ]) }

    let(:unsaved_parent) { Canvas.new(id: parent.id, shapes: [ Shape.new ]) }

    context 'using #clear' do
      it 'deletes the target from the database' do
        unsaved_parent.shapes.clear

        unsaved_parent.shapes.should be_empty

        unsaved_parent.new_record?.should be true
        parent.reload
        parent.shapes.should be_empty
      end
    end

    shared_examples 'does not delete the target from the database' do
      it 'does not delete the target from the database' do
        unsaved_parent.shapes.should be_empty

        unsaved_parent.new_record?.should be true
        parent.reload
        parent.shapes.length.should eq 1
      end
    end

    context 'using #delete_all' do
      before do
        unsaved_parent.shapes.delete_all
      end

      include_examples 'does not delete the target from the database'
    end

    context 'using #destroy_all' do
      before do
        unsaved_parent.shapes.destroy_all
      end

      include_examples 'does not delete the target from the database'
    end
  end

  context 'assigning attributes to the same association' do
    context 'setting then clearing' do
      let(:canvas) do
        Canvas.create!(shapes: [ Shape.new ])
      end

      shared_examples 'persists correctly' do
        it 'persists correctly' do
          canvas.shapes.should be_empty
          _canvas = Canvas.find(canvas.id)
          _canvas.shapes.should be_empty
        end
      end

      context 'via assignment operator' do
        before do
          canvas.shapes = [ Shape.new, Shape.new ]
          canvas.shapes = []
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via attributes=' do
        before do
          canvas.attributes = { shapes: [ Shape.new, Shape.new ] }
          canvas.attributes = { shapes: [] }
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via assign_attributes' do
        before do
          canvas.assign_attributes(shapes: [ Shape.new, Shape.new ])
          canvas.assign_attributes(shapes: [])
          canvas.save!
        end

        include_examples 'persists correctly'
      end
    end

    context 'clearing then setting' do
      let(:canvas) do
        Canvas.create!(shapes: [ Shape.new ])
      end

      shared_examples 'persists correctly' do
        it 'persists correctly' do
          canvas.shapes.length.should eq 2
          _canvas = Canvas.find(canvas.id)
          _canvas.shapes.length.should eq 2
        end
      end

      context 'via assignment operator' do
        before do
          canvas.shapes = []
          canvas.shapes = [ Shape.new, Shape.new ]
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via attributes=' do
        before do
          canvas.attributes = { shapes: [] }
          canvas.attributes = { shapes: [ Shape.new, Shape.new ] }
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via assign_attributes' do
        before do
          canvas.assign_attributes(shapes: [])
          canvas.assign_attributes(shapes: [ Shape.new, Shape.new ])
          canvas.save!
        end

        include_examples 'persists correctly'
      end
    end

    context 'updating a child then clearing' do
      let(:canvas) do
        Canvas.create!(shapes: [ Shape.new ])
      end

      shared_examples 'persists correctly' do
        it 'persists correctly' do
          canvas.shapes.should be_empty
          _canvas = Canvas.find(canvas.id)
          _canvas.shapes.should be_empty
        end
      end

      context 'via assignment operator' do
        before do
          # Mongoid uses the new value of `x` in the $pullAll query,
          # which doesn't match the document that is in the database,
          # resulting in the empty array assignment not taking effect.
          canvas.shapes.first.x = 1
          canvas.shapes = []
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via attributes=' do
        before do
          canvas.shapes.first.x = 1
          canvas.attributes = { shapes: [] }
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via assign_attributes' do
        before do
          canvas.shapes.first.x = 1
          canvas.assign_attributes(shapes: [])
          canvas.save!
        end

        include_examples 'persists correctly'
      end
    end

    context 'including duplicates in the assignment' do
      let(:canvas) do
        Canvas.create!(shapes: [ Shape.new ])
      end

      shared_examples 'persists correctly' do
        it 'persists correctly' do
          canvas.shapes.length.should eq 2
          _canvas = Canvas.find(canvas.id)
          _canvas.shapes.length.should eq 2
        end
      end

      context 'via assignment operator' do
        before do
          canvas.shapes = [ canvas.shapes.first, Shape.new, canvas.shapes.first ]
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via attributes=' do
        before do
          canvas.attributes = { shapes: [ canvas.shapes.first, Shape.new, canvas.shapes.first ] }
          canvas.save!
        end

        include_examples 'persists correctly'
      end

      context 'via assign_attributes' do
        before do
          canvas.assign_attributes(shapes: [ canvas.shapes.first, Shape.new, canvas.shapes.first ])
          canvas.save!
        end

        include_examples 'persists correctly'
      end
    end
  end

  context 'when an anonymous class defines an embeds_many association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document

        embeds_many :addresses
      end
    end

    it 'loads the association correctly' do
      expect { klass }.not_to raise_error
      expect { klass.new.addresses }.not_to raise_error
      expect(klass.new.addresses.build).to be_a Address
    end
  end

  context 'with deeply nested trees' do
    let(:post) { EmbedsManySpec::Post.create!(title: 'Post') }
    let(:child) { post.comments.create!(content: 'Child') }

    # creating grandchild will cascade to create the other documents
    let!(:grandchild) { child.comments.create!(content: 'Grandchild') }

    let(:updated_parent_title) { 'Post Updated' }
    let(:updated_grandchild_content) { 'Grandchild Updated' }

    context 'with nested attributes' do
      let(:attributes) do
        {
          title: updated_parent_title,
          comments_attributes: [
            {
              # no change for comment1
              _id: child.id,
              comments_attributes: [
                {
                  _id: grandchild.id,
                  content: updated_grandchild_content
                }
              ]
            }
          ]
        }
      end

      context 'when the grandchild is invalid' do
        let(:updated_grandchild_content) { '' } # invalid value

        it 'does not save the parent' do
          expect(post.update(attributes)).to be_falsey
          expect(post.errors).not_to be_empty
          expect(post.reload.title).not_to eq(updated_parent_title)
          expect(grandchild.reload.content).not_to eq(updated_grandchild_content)
        end
      end

      context 'when the grandchild is valid' do
        it 'saves the parent' do
          expect(post.update(attributes)).to be_truthy
          expect(post.errors).to be_empty
          expect(post.reload.title).to eq(updated_parent_title)
          expect(grandchild.reload.content).to eq(updated_grandchild_content)
        end
      end
    end
  end

  context 'when a hash is provided instead of an array for an embeds_many association' do
    let(:post) { EmbedsManySpec::Post.new(title: 'Broken post', comments: { content: 'Comment' }) }

    it 'does not raise an error on initialization' do
      expect { post }.not_to raise_error
    end

    it 'does not raise an error when accessing the association' do
      expect { post.comments }.not_to raise_error
    end

    it 'allows building new documents on the association' do
      expect(post.comments.build).to be_a EmbedsManySpec::Comment
    end
  end
end
