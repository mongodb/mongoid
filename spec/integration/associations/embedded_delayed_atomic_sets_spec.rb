# frozen_string_literal: true

require 'spec_helper'

module EmbeddedDelayedAtomicSetsSpec
  class Section
    include Mongoid::Document

    field :content

    embedded_in :parent, polymorphic: true
  end

  class Group
    include Mongoid::Document

    embedded_in :root
    embeds_many :sections, class_name: 'EmbeddedDelayedAtomicSetsSpec::Section'
    accepts_nested_attributes_for :sections
  end

  class Root
    include Mongoid::Document

    embeds_many :sections, class_name: 'EmbeddedDelayedAtomicSetsSpec::Section'
    embeds_one :group, class_name: 'EmbeddedDelayedAtomicSetsSpec::Group'
    accepts_nested_attributes_for :sections
    accepts_nested_attributes_for :group
  end
end

module NewEmbeddedChildSpec
  class Member
    include Mongoid::Document

    field :name

    embedded_in :team
  end

  class Team
    include Mongoid::Document

    embedded_in :org
    embeds_many :members, class_name: 'NewEmbeddedChildSpec::Member'
    accepts_nested_attributes_for :members
  end

  class Org
    include Mongoid::Document

    field :title

    embeds_one :team, class_name: 'NewEmbeddedChildSpec::Team'
    accepts_nested_attributes_for :team
  end
end

RSpec.describe 'embedded delayed atomic sets' do
  context 'with the same stored name' do
    let!(:root) do
      root = EmbeddedDelayedAtomicSetsSpec::Root.new
      root.sections = [ EmbeddedDelayedAtomicSetsSpec::Section.new(content: 'root-original') ]
      root.save!
      root
    end

    def stored_document
      EmbeddedDelayedAtomicSetsSpec::Root.collection.find(_id: root.id).first
    end

    def stored_contents(sections)
      sections.to_a.map { |section| section['content'] }
    end

    def document_contents(sections)
      sections.map(&:content)
    end

    # The persisted root has no group, so attributes= builds the new nested group
    # while the root sections update is still pending.
    it 'does not merge a new child into the parent association' do
      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = {
        sections: [ { _id: reloaded.sections.first.id, content: 'root-updated' } ],
        group: { sections: [ { content: 'group-new' } ] }
      }
      reloaded.save!

      stored = stored_document
      expect(stored_contents(stored['sections'])).to eq [ 'root-updated' ]
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-new' ]
      expect(document_contents(reloaded.sections)).to eq [ 'root-updated' ]
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-new' ]
    end

    it 'does not copy a new child into an empty parent association' do
      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = {
        sections: [],
        group: { sections: [ { content: 'group-new' } ] }
      }
      reloaded.save!

      stored = stored_document
      expect(stored).not_to have_key('sections')
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-new' ]
      expect(reloaded.sections).to be_empty
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-new' ]
    end

    it 'does not merge a new child when the parent association is unchanged' do
      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = { group: { sections: [ { content: 'group-new' } ] } }
      reloaded.save!

      stored = stored_document
      expect(stored_contents(stored['sections'])).to eq [ 'root-original' ]
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-new' ]
      expect(document_contents(reloaded.sections)).to eq [ 'root-original' ]
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-new' ]
    end

    it 'updates an existing group and isolates a subsequently added group' do
      root.group = EmbeddedDelayedAtomicSetsSpec::Group.new(
        sections: [ EmbeddedDelayedAtomicSetsSpec::Section.new(content: 'group-original') ]
      )
      root.save!

      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = {
        group: {
          _id: reloaded.group.id,
          sections: [ { _id: reloaded.group.sections.first.id, content: 'group-updated' } ]
        }
      }
      reloaded.save!

      stored = stored_document
      expect(stored_contents(stored['sections'])).to eq [ 'root-original' ]
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-updated' ]
      expect(document_contents(reloaded.sections)).to eq [ 'root-original' ]
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-updated' ]

      reloaded.group = nil
      reloaded.save!
      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = {
        sections: [ { _id: reloaded.sections.first.id, content: 'root-updated' } ],
        group: { sections: [ { content: 'group-new' } ] }
      }
      reloaded.save!

      stored = stored_document
      expect(stored_contents(stored['sections'])).to eq [ 'root-updated' ]
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-new' ]
      expect(document_contents(reloaded.sections)).to eq [ 'root-updated' ]
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-new' ]
    end

    it 'does not merge a new child when updating the parent through nested attributes' do
      reloaded = EmbeddedDelayedAtomicSetsSpec::Root.find(root.id)
      reloaded.attributes = {
        sections_attributes: {
          '0' => { _id: reloaded.sections.first.id, content: 'root-updated' }
        },
        group: { sections: [ { content: 'group-new' } ] }
      }
      reloaded.save!

      stored = stored_document
      expect(stored_contents(stored['sections'])).to eq [ 'root-updated' ]
      expect(stored_contents(stored.dig('group', 'sections'))).to eq [ 'group-new' ]
      expect(document_contents(reloaded.sections)).to eq [ 'root-updated' ]
      expect(document_contents(reloaded.group.sections)).to eq [ 'group-new' ]
    end
  end

  context 'when assigning a new embeds_one child with nested embeds_many' do
    let!(:org) { NewEmbeddedChildSpec::Org.create!(title: 't0') }

    it 'does not write the nested array as a root-level field' do
      reloaded = NewEmbeddedChildSpec::Org.find(org.id)
      reloaded.attributes = { title: 't1', team: { members: [ { name: 'm1' } ] } }
      reloaded.save!

      stored = NewEmbeddedChildSpec::Org.collection.find(_id: org.id).first
      expect(stored.keys).to match_array(%w[_id title team])
      expect(stored.dig('team', 'members').map { |member| member['name'] }).to eq [ 'm1' ]
    end

    it 'does not write nested attributes at the root level' do
      reloaded = NewEmbeddedChildSpec::Org.find(org.id)
      reloaded.attributes = {
        team_attributes: { members: [ { name: 'm1' } ] }
      }
      reloaded.save!

      stored = NewEmbeddedChildSpec::Org.collection.find(_id: org.id).first
      expect(stored.keys).to match_array(%w[_id title team])
      expect(stored.dig('team', 'members').map { |member| member['name'] }).to eq [ 'm1' ]
      expect(reloaded.team.members.map(&:name)).to eq [ 'm1' ]
    end

    it 'does not conflict when assigning to a newly built child' do
      reloaded = NewEmbeddedChildSpec::Org.find(org.id)
      reloaded.build_team
      reloaded.team.attributes = { members: [ { name: 'm1' } ] }
      reloaded.save!

      stored = NewEmbeddedChildSpec::Org.collection.find(_id: org.id).first
      expect(stored.dig('team', 'members').map { |member| member['name'] }).to eq [ 'm1' ]
      expect(reloaded.team.members.map(&:name)).to eq [ 'm1' ]
    end
  end
end
