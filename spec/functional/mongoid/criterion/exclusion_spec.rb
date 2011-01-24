require "spec_helper"

describe Mongoid::Criterion::Exclusion do

  before do
    Person.delete_all
  end

  describe "#excludes" do

    let(:person) do
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
end
