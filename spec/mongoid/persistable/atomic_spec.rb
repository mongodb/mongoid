require "spec_helper"

describe Mongoid::Persistable::Atomic do

  context "when using aliased field names" do

    describe "#add_to_set" do

      let(:person) do
        Person.create(array: [ "test" ])
      end

      before do
        person.add_to_set(:array, "testy")
      end

      it "adds to the aliased field" do
        expect(person.array).to eq([ "test", "testy" ])
      end

      it "persists the change" do
        expect(person.reload.array).to eq([ "test", "testy" ])
      end
    end
  end
end
