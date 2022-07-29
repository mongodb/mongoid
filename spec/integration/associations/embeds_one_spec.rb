# frozen_string_literal: true

require 'spec_helper'

describe 'embeds_one associations' do

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:canvas) do
        Canvas.create!(palette: Palette.new)
      end

      let!(:palette) { canvas.palette }

      it 'does not destroy the dependent object' do
        canvas.palette = canvas.palette
        canvas.save!
        canvas.reload
        canvas.palette.should == palette
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
      expect { klass }.to_not raise_error
      expect { klass.new.address }.to_not raise_error
      instance = klass.new
      address = Address.new
      instance.address = address
      expect(instance.address).to eq address
    end
  end
end
