require "spec_helper"

describe Mongoid::Criterion::Modification do

  before do
    Person.delete_all
  end

  [ :update, :update_all ].each do |method|

    let!(:person) do
      Person.create(:title => "Sir", :ssn => "666-66-6666")
    end

    before do
      person.addresses << Address.new(:street => "Oranienstr")
    end

    describe "##{method}" do

      let(:from_db) do
        Person.first
      end

      before do
        Person.where(:title => "Sir").send(method, :title => "Madam")
      end

      it "updates all the matching documents" do
        from_db.title.should == "Madam"
      end
    end
  end
end
