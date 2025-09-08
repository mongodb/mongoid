# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

module HabtmSpec
  class Page
    include Mongoid::Document
    embeds_many :blocks, class_name: 'HabtmSpec::Block'
  end

  class Block
    include Mongoid::Document
    embedded_in :page, class_name: 'HabtmSpec::Page'
  end

  class ImageBlock < Block
    has_and_belongs_to_many :attachments, inverse_of: nil, class_name: 'HabtmSpec::Attachment'
    accepts_nested_attributes_for :attachments
  end

  class Attachment
    include Mongoid::Document
    field :file, type: String
  end

  class Item
    include Mongoid::Document

    field :title, type: String

    has_and_belongs_to_many :colors, class_name: 'HabtmSpec::Color', inverse_of: :items

    accepts_nested_attributes_for :colors
  end

  class Beam
    include Mongoid::Document

    field :name, type: String
    validates :name, presence: true

    has_and_belongs_to_many :colors, class_name: 'HabtmSpec::Color', inverse_of: :beams

    accepts_nested_attributes_for :colors
  end

  class Color
    include Mongoid::Document

    field :name, type: String
    
    has_and_belongs_to_many :items, class_name: 'HabtmSpec::Item', inverse_of: :colors
    has_and_belongs_to_many :beams, class_name: 'HabtmSpec::Beam', inverse_of: :colors

    accepts_nested_attributes_for :items, :beams
  end
end

describe 'has_and_belongs_to_many associations' do

  context 'when an anonymous class defines a has_and_belongs_to_many association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        has_and_belongs_to_many :movies, inverse_of: nil
      end
    end

    it 'loads the association correctly' do
      expect { klass }.to_not raise_error
      expect { klass.new.movies }.to_not raise_error
      expect(klass.new.movies.build).to be_a Movie
    end
  end

  context 'when an embedded has habtm relation' do
    let(:attachment) { HabtmSpec::Attachment.create!(file: 'foo.jpg') }

    let(:page) { HabtmSpec::Page.create! }

    let(:image_block) do
      image_block = page.blocks.build({
        _type: 'HabtmSpec::ImageBlock',
        attachment_ids: [ attachment.id.to_s ],
        attachments_attributes: { '1234' => { file: 'bar.jpg', id: attachment.id.to_s } }
      })
    end

    it 'does not raise on save' do
      expect { image_block.save! }.not_to raise_error
    end
  end

  context 'with deeply nested trees' do
    let(:item) { HabtmSpec::Item.create!(title: 'Item') }
    let(:beam) { HabtmSpec::Beam.create!(name: 'Beam') }
    let!(:color) { HabtmSpec::Color.create!(name: 'Red', items: [ item ], beams: [ beam ]) }

    let(:updated_item_title) { 'Item Updated' }
    let(:updated_beam_name) { 'Beam Updated' }

    context 'with nested attributes' do
      let(:attributes) do
        {
          title: updated_item_title,
          colors_attributes: [
            {
              # no change for color
              _id: color.id,
              beams_attributes: [
                {
                  _id: beam.id,
                  name: updated_beam_name,
                }
              ]
            }
          ]
        }
      end

      context 'when the beam is invalid' do
        let(:updated_beam_name) { '' } # invalid value

        it 'will not save the parent' do
          expect(item.update(attributes)).to be_falsey
          expect(item.errors).not_to be_empty
          expect(item.reload.title).not_to eq(updated_item_title)
          expect(beam.reload.name).not_to eq(updated_beam_name)
        end
      end

      context 'when the beam is valid' do
        it 'will save the parent' do
          expect(item.update(attributes)).to be_truthy
          expect(item.errors).to be_empty
          expect(item.reload.title).to eq(updated_item_title)
          expect(beam.reload.name).to eq(updated_beam_name)
        end
      end
    end
  end
end
