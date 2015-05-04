require "spec_helper"

describe Mongoid::Traversable do

  describe "#_children" do

    let(:person) do
      Person.new(title: "King")
    end

    context "with one level of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      before do
        person.name = name
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._children).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._children).to include(address)
      end
    end

    context "with multiple levels of embedding" do

      let(:name) do
        Name.new(first_name: "Titus")
      end

      let(:address) do
        Address.new(street: "Queen St")
      end

      let(:location) do
        Location.new(name: "Work")
      end

      before do
        person.name = name
        address.locations << location
        person.addresses << address
      end

      it "includes embeds_one documents" do
        expect(person._children).to include(name)
      end

      it "includes embeds_many documents" do
        expect(person._children).to include(address)
      end

      it "includes embedded documents multiple levels deep" do
        expect(person._children).to include(location)
      end
    end
  end

  describe ".hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        expect(Circle.hereditary?).to be true
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        expect(Shape.hereditary?).to be false
      end
    end
  end

  describe "#hereditary?" do

    context "when the document is a subclass" do

      it "returns true" do
        expect(Circle.new).to be_hereditary
      end
    end

    context "when the document is not a subclass" do

      it "returns false" do
        expect(Shape.new).to_not be_hereditary
      end
    end
  end

  describe "#inherited" do

    it "duplicates the localized fields" do
      expect(Actress.localized_fields).to_not equal(Actor.localized_fields)
    end
  end

  describe "#parentize" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    it "sets the parent document" do
      expect(address._parent).to eq(person)
    end
  end

  describe "#remove_child" do

    let(:person) do
      Person.new
    end

    context "when child is an embeds one" do

      let!(:name) do
        person.build_name(first_name: "James")
      end

      before do
        person.remove_child(name)
      end

      it "removes the relation instance" do
        expect(person.name).to be_nil
      end
    end

    context "when child is an embeds many" do

      let!(:address) do
        person.addresses.build(street: "Upper St")
      end

      before do
        person.remove_child(address)
      end

      it "removes the document from the relation target" do
        expect(person.addresses).to be_empty
      end
    end
  end

  describe "#_root" do

    let(:address) do
      Address.new
    end

    let(:person) do
      Person.new
    end

    before do
      address.parentize(person)
    end

    context "when the document is not the root" do

      it "returns the root" do
        expect(address._root).to eq(person)
      end
    end

    context "when the document is the root" do

      it "returns self" do
        expect(person._root).to eq(person)
      end
    end
  end

  describe "#_root?" do

    context "when the document can be the root" do

      context "when the document is not embedded" do

        let(:band) do
          Band.new
        end

        it "returns true" do
          expect(band).to be__root
        end
      end

      context "when the document is embedded" do

        let(:root_role) do
          Role.new
        end

        context "when the document is root in a cyclic relation" do

          it "returns true" do
            expect(root_role).to be__root
          end
        end

        context "when document is embedded in a cyclic relation" do

          let(:child_role) do
            root_role.child_roles.build
          end

          it "returns false" do
            expect(child_role).to_not be__root
          end
        end
      end
    end

    context "when the document is embedded and not cyclic" do

      let(:person) do
        Person.new
      end

      let(:address) do
        person.addresses.build
      end

      it "returns false" do
        expect(address).to_not be__root
      end
    end
  end
end
