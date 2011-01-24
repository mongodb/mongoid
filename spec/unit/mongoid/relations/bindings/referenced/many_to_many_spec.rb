require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::ManyToMany do

  let(:person) do
    Person.new
  end

  let(:preference) do
    Preference.new
  end

  let(:target) do
    [ preference ]
  end

  let(:metadata) do
    Person.relations["preferences"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are bindable" do

      before do
        person.expects(:save).never
        preference.expects(:save).never
        binding.bind(:continue => true)
      end

      it "sets the inverse relation" do
        preference.people.should == [ person ]
      end

      it "sets the foreign key" do
        preference.person_ids.should == [ person.id ]
      end
    end

    context "when the documents are not bindable" do

      before do
        preference.people << person
      end

      it "does nothing" do
        person.preferences.expects(:<<).never
        binding.bind
      end
    end
  end

  describe "#bind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is bindable" do

      let(:preference_two) do
        Preference.new
      end

      before do
        binding.bind_one(preference_two, :continue => true)
      end

      it "sets the inverse relation" do
        preference_two.people.should == [ person ]
      end

      it "sets the foreign key" do
        preference_two.person_ids.should == [ person.id ]
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        person.preferences.expects(:<<).never
        binding.bind_one(preference)
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind(:continue => true)
        person.expects(:delete).never
        preference.expects(:delete).never
        binding.unbind(:continue => true)
      end

      it "removes the inverse relation" do
        preference.people.should be_empty
      end

      it "removed the foreign keys" do
        preference.person_ids.should be_empty
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        person.expects(:preferences=).never
        binding.unbind
      end
    end
  end

  describe "#unbind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind(:continue => true)
        person.expects(:delete).never
        preference.expects(:delete).never
        binding.unbind_one(target.first, :continue => true)
      end

      it "removes the inverse relation" do
        preference.people.should be_empty
      end

      it "removed the foreign keys" do
        preference.person_ids.should be_empty
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        person.expects(:preferences=).never
        binding.unbind_one(target.first)
      end
    end
  end
end
