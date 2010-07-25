require "spec_helper"

describe Mongoid::Safety do

  before do
    Person.delete_all
    Mongoid.autocreate_indexes = true
  end

  after do
    Mongoid.autocreate_indexes = false
  end

  context "when global safe mode is false" do

    before do
      Mongoid.persist_in_safe_mode = false
    end

    describe ".create" do

      before do
        Person.safely.create(:ssn => "432-97-1111")
      end

      it "inserts the document" do
        Person.count.should == 1
      end

      it "overrides the global config option" do
        lambda {
          Person.safely.create(:ssn => "432-97-1111")
        }.should raise_error(Mongo::OperationFailure)
      end
    end
  end
end
