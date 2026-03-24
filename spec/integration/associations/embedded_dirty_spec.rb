# frozen_string_literal: true

require 'spec_helper'
require_relative '../../mongoid/association/embedded/embeds_many_models'
require_relative '../../mongoid/association/embedded/embeds_one_models'

describe 'embedded associations' do
  describe 'dirty tracking' do
    context 'when association is cyclic' do
      before do
        # create deeply nested record
        a = EmmOuter.create(level: 0)
        level = 1
        iter = a.inners.create(level: level)
        loop do
          iter.friends.create(level: (level += 1))
          iter = iter.friends[0]
          break if level == 40
        end
      end

      let(:subject) { EmmOuter.first }

      it 'performs dirty tracking efficiently' do
        subject.changed?.should be false
      end

      it 'calculates the descendants properly' do
        expect(subject._descendants.length).to eq(40)
      end
    end

    context 'when association is cyclic and the _id is nil' do
      before do
        # create deeply nested record
        a = EmmOuter.create(level: 0)
        level = 1
        iter = a.inners.create(id: nil, level: level)
        loop do
          iter.friends.create(id: nil, level: (level += 1))
          iter = iter.friends[0]
          break if level == 40
        end
      end

      let(:subject) { EmmOuter.first }

      it 'performs dirty tracking efficiently' do
        subject.changed?.should be false
      end

      it 'calculates the descendants properly' do
        expect(subject._descendants.length).to eq(40)
      end
    end
  end
end
