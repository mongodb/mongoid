require "spec_helper"

describe "Marshaling", Mongoid::Document do

  context "instance with an instantiated relation with extensions" do

    let(:person) do
      Person.new.tap do |person|
        person.addresses.extension
      end
    end

    describe Marshal, ".dump" do

      it "successfully dumps the document" do
        expect { Marshal.dump(person) }.not_to raise_error
      end

    end

    describe Marshal, ".load" do

      it "successfully loads the document" do
        expect { Marshal.load Marshal.dump(person) }.not_to raise_error
      end

    end

  end

end
