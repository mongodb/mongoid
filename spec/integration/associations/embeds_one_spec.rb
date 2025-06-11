# frozen_string_literal: true

require 'spec_helper'

describe 'embeds_one associations' do
  context 'when re-associating the same object' do
    context 'with dependent: destroy' do
      let(:canvas) do
        Canvas.create!(palette: Palette.new)
      end

      let!(:palette) { canvas.palette }

      it 'does not destroy the dependent object' do
        canvas.palette = canvas.palette
        canvas.save!
        canvas.reload
        expect(canvas.palette).to eq palette
      end
    end
  end

  context 'when an anonymous class defines an embeds_one association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        embeds_one :address
      end
    end

    it 'loads the association correctly' do
      expect { klass }.not_to raise_error
      expect { klass.new.address }.not_to raise_error
      instance = klass.new
      address = Address.new
      instance.address = address
      expect(instance.address).to eq address
    end
  end

  context 'when parent is persisted' do
    let!(:person) do
      Person.create!
    end

    context 'when assigning the new child' do
      context 'when assigning an attribute to the child' do
        before do
          # person.reload
          person.name = Name.new
          person.name.first_name = 'Dmitry'
          person.save!
        end

        it 'persists the child' do
          expect(person.reload.name.first_name).to eq 'Dmitry'
        end
      end
    end
  end
end
