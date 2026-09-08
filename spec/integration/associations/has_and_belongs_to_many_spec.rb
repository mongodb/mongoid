# frozen_string_literal: true

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

    # The nested attributes are processed before the attachment_ids
    # assignment is applied, so at that point the id is not yet in the
    # association and resolving it requires a collection-wide lookup.
    context 'when allow_reparenting_via_nested_attributes is false' do
      config_override :allow_reparenting_via_nested_attributes, false

      it 'raises a document not found error' do
        expect { image_block.save! }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'when allow_reparenting_via_nested_attributes is true' do
      config_override :allow_reparenting_via_nested_attributes, true

      it 'does not raise on save' do
        expect { image_block.save! }.not_to raise_error
      end
    end
  end
end
