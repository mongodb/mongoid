# frozen_string_literal: true
# encoding: utf-8

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
end
