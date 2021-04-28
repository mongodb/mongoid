# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'embeds_many associations' do

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:canvas) do
        Canvas.create!(shapes: [Shape.new])
      end

      let!(:shape) { canvas.shapes.first }

      it 'does not destroy the dependent object' do
        canvas.shapes = [shape]
        canvas.save!
        canvas.reload
        canvas.shapes.should == [shape]
      end
    end
  end

  context 'clearing association when parent is not saved' do
    let!(:parent) { Canvas.create!(shapes: [Shape.new]) }

    let(:unsaved_parent) { Canvas.new(id: parent.id, shapes: [Shape.new]) }

    context "using #clear" do
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
        parent.shapes.length.should == 1
      end
    end

    context "using #delete_all" do
      before do
        unsaved_parent.shapes.delete_all
      end

      include_examples 'does not delete the target from the database'
    end

    context "using #destroy_all" do
      before do
        unsaved_parent.shapes.destroy_all
      end

      include_examples 'does not delete the target from the database'
    end
  end
end
