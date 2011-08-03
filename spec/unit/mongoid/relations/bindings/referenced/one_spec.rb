require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::One do

  let(:person) do
    Person.new
  end

  let(:game) do
    Game.new
  end

  let(:metadata) do
    Person.relations["game"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, game, metadata)
    end

    context "when the document is bindable" do

      before do
        person.expects(:save).never
        game.expects(:save).never
        binding.bind
      end

      it "sets the inverse relation" do
        game.person.should == person
      end

      it "sets the foreign key" do
        game.person_id.should == person.id
      end
    end

    context "when the document is not bindable" do

      before do
        game.person = person
      end

      it "does nothing" do
        person.expects(:game=).never
        binding.bind
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, game, metadata)
    end

    context "when the document is unbindable" do

      before do
        binding.bind
        person.expects(:delete).never
        game.expects(:delete).never
        binding.unbind
      end

      it "removes the inverse relation" do
        game.person.should be_nil
      end

      it "removed the foreign key" do
        game.person_id.should be_nil
      end
    end

    context "when the document is not unbindable" do

      it "does nothing" do
        person.expects(:game=).never
        binding.unbind
      end
    end
  end
end
