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
end
