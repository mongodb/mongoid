# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Cacheable do

  let!(:depeche_mode) do
    Band.create!(name: "Depeche Mode")
  end

  let!(:new_order) do
    Band.create!(name: "New Order")
  end

  let!(:rolling_stones) do
    Band.create!(name: "The Rolling Stones")
  end

  describe "#count" do
    let(:criteria) do
      Band.all.cache
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    # TODO: get from loaded cache?
    context "when the method was called before" do

      before do
        context.count
      end

      context "when not modifying the context" do

        it "returns the count without touching the database" do
          expect_any_instance_of(Mongo::Collection::View).to receive(:count_documents).never
          expect(context.count).to eq(3)
        end
      end

      context "when modifying the limit" do
        let(:options) { { limit: 1 } }

        it "returns the correct count and touches the database" do
          expect_any_instance_of(Mongo::Collection::View).to receive(:count).never
          expect(context.count(options)).to eq(1)
        end
      end

      context "when modifying the projection or sort" do
        let(:options) { { projection: { _id: 0 }, sort: { _id: -1 } } }

        it "returns the count without touching the database" do
          expect_any_instance_of(Mongo::Collection::View).to receive(:count_documents).never
          expect(context.count).to eq(3)
        end
      end
    end
  end

  xdescribe "#exists?" do

    let(:criteria) do
      Band.where(name: "Depeche Mode").cache
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when the cache is loaded" do

      before do
        context.to_a
      end

      it "returns the last document without touching the database" do
        expect(context).to receive(:view).never
        expect(context.last).to eq(depeche_mode)
      end
    end

    context "when exists? was called before" do

      before do
        context.exists?
      end


    end
  end
end
