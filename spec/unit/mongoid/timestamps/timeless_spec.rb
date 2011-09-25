require "spec_helper"

describe Mongoid::Timestamps::Timeless do

  describe "#timeless" do

    let(:person) do
      Person.new
    end

    context "when used as a proxy method" do

      context "when used on the document instance" do

        let!(:timeless) do
          person.timeless
        end

        after do
          Mongoid::Threaded.timeless = false
        end

        it "adds the timestamping options" do
          Mongoid::Threaded.timeless.should be_true
        end

        it "returns the document" do
          timeless.should eq(person)
        end
      end

      context "when used on the class" do

        let!(:timeless) do
          Person.timeless
        end

        after do
          Mongoid::Threaded.timeless = false
        end

        it "adds the timestamping options" do
          Mongoid::Threaded.timeless.should be_true
        end

        it "returns the class" do
          timeless.should eq(Person)
        end
      end
    end
  end
end
