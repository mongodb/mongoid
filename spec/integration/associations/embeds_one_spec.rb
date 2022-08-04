# frozen_string_literal: true

require 'spec_helper'
require_relative '../../mongoid/association/embedded/embeds_one_models'

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

  context 'when embedded document is removed resulting in invalid parent' do
    let!(:parent) do
      EomValidatingParent.create!(child: EomValidatingChild.new)
    end

    shared_examples 'removes embedded document and leaves parent invalid' do
      # This behavior may change if MONGOID-3573 is done.
      it 'removes embedded document and leaves parent invalid' do
        operation

        parent.reload

        parent.child.should be nil
        parent.valid?.should be false
      end
    end

    context 'nullify' do
      let(:operation) do
        # saves immediately
        parent.child = nil
      end

      include_examples 'removes embedded document and leaves parent invalid'
    end

    context 'delete' do
      let(:operation) do
        # saves immediately
        parent.child.delete
      end

      include_examples 'removes embedded document and leaves parent invalid'
    end

    context 'destroy' do
      let(:operation) do
        # saves immediately
        parent.child.destroy
      end

      include_examples 'removes embedded document and leaves parent invalid'
    end
  end
end
