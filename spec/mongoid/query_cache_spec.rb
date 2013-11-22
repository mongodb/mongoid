require "spec_helper"

describe Mongoid::QueryCache do

  context "when querying in the same collection" do

    before do
      Band.all.to_a
    end

    context "with same selector" do

      it "does not query again" do
        expect_no_queries do
          Band.all.to_a
        end
      end
    end

    context "with different selector" do

      it "queries again" do
        expect_query(1) do
          Band.where(id: 1).to_a
        end
      end
    end
  end

  context "when querying in different collection" do

    before do
      Person.all.to_a
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end
end
