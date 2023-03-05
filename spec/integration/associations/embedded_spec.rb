# frozen_string_literal: true

require 'spec_helper'
require_relative '../../mongoid/association/embedded/embeds_many_models'
require_relative '../../mongoid/association/embedded/embeds_one_models'

describe 'embedded associations' do
  context 'without default order' do
    let(:congress) do
      EmmCongress.create!
    end

    let(:legislator) do
      EmmLegislator.create!(congress: congress, a: 1)
    end

    shared_examples_for 'an embedded association' do
      it 'adds child documents to parent association object' do
        legislator
        expect(congress.legislators._target).to eq([legislator])
      end

      it 'adds child documents to parent association object criteria' do
        legislator
        expect(congress.legislators.criteria.documents).to eq([legislator])
      end

      it 'populates documents on parent association object' do
        expect(congress.legislators.documents).to eq([legislator])
      end

      it 'returns created child when referencing embedded association' do
        expect(congress.legislators).to eq([legislator])
      end

      it 'returns created child when referencing Criteria created from embedded association' do
        expect(congress.legislators.all).to be_a(Mongoid::Criteria)
        expect(congress.legislators.all.to_a).to eq([legislator])
      end
    end

    context 'when association was not previously referenced' do
      before do
        legislator
      end

      it_behaves_like 'an embedded association'
    end

    context 'when association was previously referenced' do
      before do
        # This query must be before the product is created
        congress.legislators.where(a: 1).first

        legislator
      end

      it_behaves_like 'an embedded association'
    end
  end

  context 'with default order' do
    let(:manufactory) do
      EmmManufactory.create!
    end

    let(:product) do
      EmmProduct.create!(manufactory: manufactory, name: 'Car')
    end

    shared_examples_for 'adds child documents to parent association' do
      it 'adds child documents to parent association' do
        expect(manufactory.products._target).to eq([product])
      end
    end

    shared_examples_for 'an embedded association' do
      it 'adds child documents to parent association object' do
        product
        expect(manufactory.products._target).to eq([product])
      end

      it 'adds child documents to parent association object criteria' do
        product
        expect(manufactory.products.criteria.documents).to eq([product])
      end

      it 'populates documents on parent association object' do
        expect(manufactory.products.documents).to eq([product])
      end

      it 'returns created child when referencing embedded association' do
        expect(manufactory.products).to eq([product])
      end

      it 'returns created child when referencing Criteria created from embedded association' do
        expect(manufactory.products.all).to be_a(Mongoid::Criteria)
        expect(manufactory.products.all.to_a).to eq([product])
      end
    end

    context 'when association is not loaded' do
      before do
        product
      end

      it_behaves_like 'an embedded association'
    end

    context 'when association is loaded' do
      before do
        # This query must be before the product is created
        manufactory.products.where(name: "Car").first

        product
      end

      it_behaves_like 'an embedded association'
    end
  end

  describe 'parent association' do
    let(:parent) do
      parent_cls.new
    end

    context 'embeds_one' do

      shared_examples 'is set' do
        it 'is set' do
          parent.child = child_cls.new
          expect(parent.child.parent).to eq(parent)
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
          expect(child.congress).to eq(parent)
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

  describe 'updated_at on parent' do
    context 'when child is added' do
      context 'embeds_one' do
        let(:parent) { EomParent.create! }

        it 'updates' do
          first_updated_at = parent.updated_at

          parent.child = EomChild.new
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end

      context 'embeds_many' do
        let(:parent) { EmmCongress.create! }

        it 'updates' do
          first_updated_at = parent.updated_at

          parent.legislators << EmmLegislator.new
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end
    end

    context 'when child is updated' do
      context 'embeds_one' do
        let(:parent) { EomParent.create!(child: EomChild.new) }

        it 'updates' do
          first_updated_at = parent.updated_at

          parent.child.a = 42
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end

      context 'embeds_many' do
        let(:parent) { EmmCongress.create!(legislators: [EmmLegislator.new]) }

        it 'updates' do
          first_updated_at = parent.updated_at

          parent.legislators.first.a = 42
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end
    end

    context 'when child is removed' do
      context 'embeds_one' do
        let(:parent) { EomParent.create!(child: EomChild.new) }

        it 'updates' do
          first_updated_at = parent.updated_at

          parent.child = nil
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end

      context 'embeds_many' do
        let(:parent) { EmmCongress.create!(legislators: [EmmLegislator.new]) }

        it 'updates' do
          pending 'https://jira.mongodb.org/browse/MONGOID-3252'

          first_updated_at = parent.updated_at

          parent.legislators.clear
          parent.save!

          expect(parent.updated_at).to be > first_updated_at
        end
      end
    end
  end

  context "when summing properties on an embedded child" do
    let(:user) { EmmUser.new }
    before do
      user.orders.build(amount: 200)
      expect(user.orders.sum(:amount)).to eq(200)

      user.orders.delete_all
      user.orders.build(amount: 500)
    end

    it "the cache is cleared after deletion" do
      expect(user.orders.sum(:amount)).to eq(500)
    end
  end

  context 'when modifying an embedded document & removing another embedded document' do
    let(:user) do
      EmmUser.create!(orders: [
        EmmOrder.new(sku: 0, amount: 0),
        EmmOrder.new(sku: 1, amount: 1),
        EmmOrder.new(sku: 2, amount: 2),
      ])
    end

    context 'when modifying first and removing second' do
      it 'works correctly' do
        user.orders[1].assign_attributes(amount: 10)
        user.orders[0].destroy
        user.save!
        user.reload

        expect(user.orders.map do
          |order| [order.sku, order.amount]
        end).to eq([[1, 10], [2, 2]])
      end
    end

    context 'when removing first and modifying second' do
      it 'works correctly' do
        user.orders[0].destroy
        user.orders[1].assign_attributes(amount: 20)
        user.save!
        user.reload

        expect(user.orders.map do
          |order| [order.sku, order.amount]
        end).to eq([[1, 1], [2, 20]])
      end
    end
  end

  context 'when modifying a nested embedded document & removing another nested embedded document' do
    let(:user) do
      EmmUser.create!(orders: [
        EmmOrder.new(sku: 0, surcharges: [EmmSurcharge.new(amount: 0)]),
        EmmOrder.new(sku: 1, surcharges: [EmmSurcharge.new(amount: 1)]),
        EmmOrder.new(sku: 2, surcharges: [EmmSurcharge.new(amount: 2)]),
      ])
    end

    context 'when modifying first and removing second' do
      it 'works correctly' do
        pending 'MONGOID-5364'

        user.orders[1].assign_attributes(surcharges: [amount: 10])
        user.orders[0].destroy
        user.save!
        user.reload

        expect(user.orders.map do
          |order| [order.sku, order.surcharges.first.amount]
        end).to eq([[1, 10], [2, 2]])
      end
    end

    context 'when removing first and modifying second' do
      it 'works correctly' do
        user.orders[0].destroy
        user.orders[1].assign_attributes(surcharges: [amount: 20])
        user.save!
        user.reload

        expect(user.orders.map do
          |order| [order.sku, order.surcharges.first.amount]
        end).to eq([[1, 1], [2, 20]])
      end
    end
  end
end
