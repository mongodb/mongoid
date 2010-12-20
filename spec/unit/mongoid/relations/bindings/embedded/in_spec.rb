require "spec_helper"

describe Mongoid::Relations::Bindings::Embedded::In do

  let(:person) do
    Person.new
  end

  let(:name) do
    Name.new
  end

  let(:address) do
    Address.new
  end

  let(:name_metadata) do
    Name.relations["namable"]
  end

  let(:address_metadata) do
    Address.relations["addressable"]
  end

  describe "#bind" do

    context "when the child of an embeds one" do

      let(:binding) do
        described_class.new(name, person, name_metadata)
      end

      context "when the document is bindable" do

        before do
          binding.bind
        end

        it "parentizes the documents" do
          name._parent.should == person
        end

        it "sets the inverse relation" do
          person.name.should == name
        end
      end

      context "when the document is not bindable" do

        before do
          person.name = name
        end

        it "does nothing" do
          name.expects(:namable=).never
          binding.bind
        end
      end
    end

    context "when the child of an embeds many" do

      let(:binding) do
        described_class.new(address, person, address_metadata)
      end

      context "when the document is bindable" do

        before do
          binding.bind
        end

        it "parentizes the documents" do
          address._parent.should == person
        end

        it "sets the inverse relation" do
          person.addresses.should include(address)
        end
      end

      context "when the document is not bindable" do

        before do
          person.addresses = [ address ]
        end

        it "does nothing" do
          address.expects(:addressable=).never
          binding.bind
        end
      end
    end
  end

  describe "#unbind" do

    context "when the child of an embeds one" do

      let(:binding) do
        described_class.new(name, person, name_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          binding.unbind
        end

        it "removes the inverse relation" do
          person.name.should be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          name.expects(:namable=).never
          binding.unbind
        end
      end
    end

    context "when the child of an embeds many" do

      let(:binding) do
        described_class.new(address, person, address_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          binding.unbind
        end

        it "removes the inverse relation" do
          person.addresses.should be_empty
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          address.expects(:addressable=).never
          binding.unbind
        end
      end
    end
  end
end
