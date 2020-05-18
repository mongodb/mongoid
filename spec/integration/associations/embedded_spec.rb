# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'
require_relative '../../mongoid/association/embedded/embeds_many_models'
require_relative '../../mongoid/association/embedded/embeds_one_models'

describe 'embedded associations' do

  describe 'parent association' do
    let(:parent) do
      parent_cls.new
    end

    context 'embeds_one' do

      shared_examples 'is set' do
        it 'is set' do
          parent.child = child_cls.new
          parent.child.parent.should == parent
        end
      end

      context 'class_name set without leading ::' do
        let(:parent_cls) { EomParent }
        let(:child_cls) { EomChild }

        it_behaves_like 'is set'
      end

      context 'class_name set with leading ::' do
        let(:parent_cls) { EomCcParent }
        let(:child_cls) { EomCcChild }

        it_behaves_like 'is set'
      end
    end

    context 'embeds_many' do

      let(:child) { parent.legislators.new }

      shared_examples 'is set' do
        it 'is set' do
          child.congress.should == parent
        end
      end

      context 'class_name set without leading ::' do
        let(:parent_cls) { EmmCongress }

        it_behaves_like 'is set'
      end

      context 'class_name set with leading ::' do
        let(:parent_cls) { EmmCcCongress }

        it_behaves_like 'is set'
      end
    end
  end
end
