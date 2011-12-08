require "spec_helper"

describe Mongoid::Criterion::Optional do

  before do
    [ Person, Book ].each(&:delete_all)
  end

  describe "#descending" do

    let!(:first) do
      Person.create(:ssn => "123-45-6789")
    end

    let!(:second) do
      Person.create(:ssn => "123-45-6780")
    end

    context "when combined with a #first" do

      context "when sorting by :_id" do

        let(:sorted) do
          Person.descending(:_id).first
        end

        it "does not override the criteria" do
          sorted.should eq(second)
        end
      end

      context "when sorting by '_id'" do

        let(:sorted) do
          Person.descending("_id").first
        end

        it "does not override the criteria" do
          sorted.should eq(second)
        end
      end
    end
  end

  context "when chaining multiple sort criterion" do

    let(:asc) do
      Book.all.asc(:title)
    end

    let(:desc) do
      asc.desc(:title)
    end

    let(:titles) do
      %w/ a b c d /
    end

    before do
      titles.each do |name|
        Book.create(:title => name)
      end
    end

    it "does not overwrite the original sort options" do
      asc.map(&:title).should eq(titles)
    end

    it "applies the new sort options" do
      desc.map(&:title).should eq(titles.reverse)
    end
  end
end
