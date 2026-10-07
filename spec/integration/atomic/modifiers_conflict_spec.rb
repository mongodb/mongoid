# frozen_string_literal: true

require 'spec_helper'

class AtomicModifiersConflictGrade
  include Mongoid::Document
end

class AtomicModifiersConflictParent
  include Mongoid::Document

  embeds_many :children, class_name: 'AtomicModifiersConflictChild'
  accepts_nested_attributes_for :children, allow_destroy: true
end

class AtomicModifiersConflictChild
  include Mongoid::Document

  field :label, type: String
  has_and_belongs_to_many :grades, class_name: 'AtomicModifiersConflictGrade', inverse_of: nil
  embeds_many :leaves, class_name: 'AtomicModifiersConflictLeaf'
  accepts_nested_attributes_for :leaves, allow_destroy: true
  embeds_one :detail, class_name: 'AtomicModifiersConflictDetail'

  embedded_in :parent, class_name: 'AtomicModifiersConflictParent'
end

class AtomicModifiersConflictLeaf
  include Mongoid::Document

  field :label, type: String
  has_and_belongs_to_many :grades, class_name: 'AtomicModifiersConflictGrade', inverse_of: nil
  embeds_many :twigs, class_name: 'AtomicModifiersConflictTwig'
  accepts_nested_attributes_for :twigs, allow_destroy: true

  embedded_in :child, class_name: 'AtomicModifiersConflictChild'
end

class AtomicModifiersConflictDetail
  include Mongoid::Document

  field :label, type: String

  embedded_in :child, class_name: 'AtomicModifiersConflictChild'
end

class AtomicModifiersConflictTwig
  include Mongoid::Document

  field :label, type: String

  embedded_in :leaf, class_name: 'AtomicModifiersConflictLeaf'
end

describe 'atomic updates to embedded arrays with overlapping paths' do
  let!(:grade_ids) { Array.new(3) { AtomicModifiersConflictGrade.create!.id } }

  let!(:parent) do
    AtomicModifiersConflictParent.create!(
      children: [
        build_child('a', [ grade_ids[0] ], 'ad'),
        build_child('b', [ grade_ids[0], grade_ids[1] ], 'bd')
      ]
    )
  end

  let!(:parent_id) { parent.id }

  def persisted_children
    AtomicModifiersConflictParent.collection.find(_id: parent_id).first['children']
  end

  def build_child(label, child_grade_ids, detail_label)
    AtomicModifiersConflictChild.new(
      label: label,
      grade_ids: child_grade_ids,
      detail: AtomicModifiersConflictDetail.new(label: detail_label),
      leaves: [ build_leaf("#{label}1"), build_leaf("#{label}2") ]
    )
  end

  def build_leaf(label)
    AtomicModifiersConflictLeaf.new(
      label: label,
      grade_ids: [ grade_ids[0] ],
      twigs: [
        AtomicModifiersConflictTwig.new(label: "#{label}x"),
        AtomicModifiersConflictTwig.new(label: "#{label}y")
      ]
    )
  end

  def labels_and_grade_ids
    persisted_children.map { |child| [ child['label'], child['grade_ids'] ] }
  end

  def document_by_label(documents, label)
    documents.detect { |document| document.label == label }
  end

  it 'saves an existing child addToSet when another child is pushed' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    child, = parent.children.to_a

    parent.children.build(label: 'c', grade_ids: [ grade_ids[1] ])
    child.grade_ids = child.grade_ids + [ grade_ids[2] ]
    parent.save!

    expect(labels_and_grade_ids).to eq(
      [
        [ 'a', [ grade_ids[0], grade_ids[2] ] ],
        [ 'b', [ grade_ids[0], grade_ids[1] ] ],
        [ 'c', [ grade_ids[1] ] ]
      ]
    )
  end

  it 'saves a surviving child addToSet after a preceding child is pulled' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a

    parent.children_attributes = [ { id: first.id, _destroy: true } ]
    second.grade_ids = second.grade_ids + [ grade_ids[2] ]
    parent.save!

    expect(labels_and_grade_ids).to eq(
      [
        [ 'b', [ grade_ids[0], grade_ids[1], grade_ids[2] ] ]
      ]
    )
  end

  it 'saves a surviving child pullAll after a preceding child is pulled' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a

    parent.children_attributes = [ { id: first.id, _destroy: true } ]
    second.grade_ids = second.grade_ids - [ grade_ids[0] ]
    parent.save!

    expect(labels_and_grade_ids).to eq([ [ 'b', [ grade_ids[1] ] ] ])
  end

  it 'keeps a child unset and sibling pull conflict as a database error' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a

    parent.children_attributes = [ { id: first.id, _destroy: true } ]
    second.remove_attribute(:label)
    expect { parent.save! }.to raise_error(Mongo::Error::OperationFailure, /\[40\]/)
    expect(labels_and_grade_ids).to eq(
      [
        [ 'a', [ grade_ids[0] ] ],
        [ 'b', [ grade_ids[0], grade_ids[1] ] ]
      ]
    )
  end

  it 'keeps a child unset and sibling push and pull conflict as a database error' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a

    parent.children.build(label: 'c')
    parent.children_attributes = [ { id: first.id, _destroy: true } ]
    second.remove_attribute(:label)
    expect { parent.save! }.to raise_error(Mongo::Error::OperationFailure, /\[40\]/)
    expect(labels_and_grade_ids.map(&:first)).to eq(%w[a b])
  end

  it 'keeps an embeds_one unset and sibling pull conflict as a database error' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a

    parent.children_attributes = [ { id: first.id, _destroy: true } ]
    second.attributes = { detail: nil }

    expect { parent.save! }.to raise_error(Mongo::Error::OperationFailure, /\[40\]/)
    expect(persisted_children.map { |child| child['detail']&.fetch('label') }).to eq(%w[ad bd])
  end

  it 'saves nested pulls after removing a preceding child' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a
    removed_leaf = document_by_label(second.leaves, 'b1')

    parent.children_attributes = [
      { id: first.id, _destroy: true },
      { id: second.id, leaves_attributes: [ { id: removed_leaf.id, _destroy: true } ] }
    ]
    parent.save!

    actual = persisted_children.map do |child|
      [ child['label'], child['leaves'].map { |leaf| leaf['label'] } ]
    end
    expect(actual).to eq([ [ 'b', [ 'b2' ] ] ])
  end

  it 'saves an unset before pushing another child' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    _, child = parent.children.to_a

    parent.children.build(label: 'c')
    child.remove_attribute(:label)
    parent.save!

    expect(labels_and_grade_ids).to eq(
      [
        [ 'a', [ grade_ids[0] ] ],
        [ nil, [ grade_ids[0], grade_ids[1] ] ],
        [ 'c', nil ]
      ]
    )
  end

  it 'saves an embeds_one unset before pushing another child' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    _, child = parent.children.to_a

    parent.children.build(label: 'c')
    child.attributes = { detail: nil }
    parent.save!

    expect(persisted_children.map { |document| document['detail']&.fetch('label') }).to eq([ 'ad', nil, nil ])
  end

  it 'saves an empty embedded array assignment before pushing another child' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    _, child = parent.children.to_a

    parent.children.build(label: 'c')
    child.attributes = { leaves: [] }
    parent.save!

    expect(persisted_children.map { |document| document['leaves']&.map { |leaf| leaf['label'] } }).to eq(
      [
        %w[a1 a2], nil, nil
      ]
    )
  end

  it 'saves a nested pull when another child is pushed' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    _, child = parent.children.to_a
    removed_leaf = document_by_label(child.leaves, 'b1')

    parent.children.build(label: 'c')
    child.leaves_attributes = [ { id: removed_leaf.id, _destroy: true } ]
    parent.save!

    expect(persisted_children.map do |document|
      [ document['label'], document['leaves']&.map { |leaf| leaf['label'] } ]
    end).to eq(
      [
        [ 'a', %w[a1 a2] ],
        [ 'b', [ 'b2' ] ],
        [ 'c', nil ]
      ]
    )
  end

  it 'saves three levels of nested pulls in array index order' do
    parent = AtomicModifiersConflictParent.find(parent_id)
    first, second = parent.children.to_a
    removed_leaf = document_by_label(second.leaves, 'b1')
    retained_leaf = document_by_label(second.leaves, 'b2')
    removed_twig = document_by_label(retained_leaf.twigs, 'b2x')

    parent.children_attributes = [
      { id: first.id, _destroy: true },
      {
        id: second.id,
        leaves_attributes: [
          { id: removed_leaf.id, _destroy: true },
          { id: retained_leaf.id, twigs_attributes: [ { id: removed_twig.id, _destroy: true } ] }
        ]
      }
    ]
    parent.save!

    persisted_child = persisted_children.first
    expect(persisted_child['label']).to eq('b')
    actual = persisted_child['leaves'].map do |leaf|
      [ leaf['label'], leaf['twigs'].map { |twig| twig['label'] } ]
    end
    expect(actual).to eq(
      [
        [ 'b2', [ 'b2y' ] ]
      ]
    )
  end
end
