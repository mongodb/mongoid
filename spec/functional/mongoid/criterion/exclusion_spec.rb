require "spec_helper"

describe Mongoid::Criterion::Exclusion do

  before do
    Person.delete_all
  end

  describe "#excludes" do

    let!(:person) do
      Person.create(
        :title => "Sir",
        :age => 100,
        :aliases => ["D", "Durran"],
        :ssn => "666666666"
      )
    end

    context "when passed id" do

      let(:documents) do
        Person.excludes(:id => person.id)
      end

      it "it properly excludes the documents" do
        documents.should be_empty
      end
    end

    context "when passed _id" do

      let(:documents) do
        Person.excludes(:_id => person.id)
      end

      it "it properly excludes the documents" do
        documents.should be_empty
      end
    end
  end

  describe "#without" do

    let!(:person) do
      Person.create(:ssn => "123-22-1212")
    end

    context "when used in a named scope" do

      let(:documents) do
        Person.without_ssn
      end

      it "limits the document fields" do
        documents.first.ssn.should be_nil
      end
    end
  end
end
