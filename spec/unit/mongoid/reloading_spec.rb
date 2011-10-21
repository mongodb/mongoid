require "spec_helper"

describe Mongoid::Reloading do

  describe "#reload" do

    let(:collection) do
      stub
    end

    let(:person) do
      Person.new(:title => "Sir")
    end

    let!(:name) do
      person.build_name(:first_name => "James")
    end

    context "when the document has been persisted" do

      let(:reloaded) do
        person.reload
      end

      let!(:attributes) do
        {
          "title" => "Mrs",
          "name" => { "first_name" => "Money" }
        }
      end

      before do
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(:_id => person.id).returns(attributes)
      end

      it "reloads the attributes" do
        reloaded.title.should == "Mrs"
      end

      it "reloads the relations" do
        reloaded.name.first_name.should == "Money"
      end
    end

    context "when the document is new" do

      before do
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(:_id => person.id).returns(nil)
      end

      context "when raising a not found error" do

        before do
          Mongoid.raise_not_found_error = true
        end

        it "raises an error" do
          expect {
            person.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when not raising a not found error" do

        before do
          Mongoid.raise_not_found_error = false
        end

        after do
          Mongoid.raise_not_found_error = true
        end

        it "sets the attributes to empty" do
          person.reload.title.should be_nil
        end
      end
    end

    context "when a relation is set as nil" do

      before do
        person.instance_variable_set(:@name, nil)
        person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(
          :_id => person.id
        ).returns({ "title" => "Sir" })
      end

      let(:reloaded) do
        person.reload
      end

      it "removes the instance variable" do
        reloaded.instance_variable_defined?(:@name).should be_false
      end
    end
  end
end
