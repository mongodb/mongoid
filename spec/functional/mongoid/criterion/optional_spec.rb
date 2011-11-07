require "spec_helper"

describe Mongoid::Criterion::Optional do

  before do
    Person.delete_all
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
end
