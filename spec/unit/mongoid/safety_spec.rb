require "spec_helper"

describe Mongoid::Safety do

  describe ".safely" do

    let(:proxy) do
      Person.safely
    end

    it "returns a safe proxy" do
      proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
    end

    it "proxies the class" do
      proxy.target.should == Person
    end
  end

  describe "#safely" do

    let(:person) do
      Person.new
    end

    let(:proxy) do
      person.safely
    end

    it "returns a safe proxy" do
      proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
    end

    it "proxies the document" do
      proxy.target.should == person
    end
  end

  context "when proxying a document instance" do

    let(:command) do
      stub
    end

    let(:person) do
      Person.new
    end

    describe "#delete" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.delete
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.delete(:safe => true)
        end
      end
    end

    describe "#destroy" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.destroy
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.destroy(:safe => true)
        end
      end
    end

    describe "#insert" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.insert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.insert(:safe => true)
        end
      end
    end

    describe "#save!" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.insert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.insert(:safe => true)
        end
      end
    end

    describe "#update" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.update
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.update(:safe => true)
        end
      end
    end

    describe "#update_attributes" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.update_attributes(:title => "Sir")
        end
      end
    end

    describe "#update_attributes" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.update_attributes!(:title => "Sir")
        end
      end
    end

    describe "#upsert" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(person)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          person.safely.upsert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          person.safely.upsert(:safe => true)
        end
      end
    end
  end

  context "when proxying a class" do

    let(:command) do
      stub
    end

    let(:person) do
      Person.new
    end

    describe "#create" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        Person.expects(:new).returns(person)
        command.expects(:persist).returns(person)
      end

      context "without attributes provided" do

        it "sends the safe mode option to the command" do
          Person.safely.create
        end
      end

      context "with attributes provided" do

        it "sends the safe mode option to the command" do
          Person.safely.create(:title => "Sir")
        end
      end
    end

    describe "#create!" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        Person.expects(:new).returns(person)
        command.expects(:persist).returns(person)
      end

      context "without attributes provided" do

        it "sends the safe mode option to the command" do
          Person.safely.create!
        end
      end

      context "with attributes provided" do

        it "sends the safe mode option to the command" do
          Person.safely.create!(:title => "Sir")
        end
      end
    end

    describe "#delete_all" do

      context "without conditions provided" do

        before do
          Mongoid::Persistence::RemoveAll.expects(:new).with(
            Person,
            { :validate => false, :safe => true },
            {}
          ).returns(command)
          command.expects(:persist).returns(true)
        end

        it "sends the safe mode option to the command" do
          Person.safely.delete_all
        end
      end

      context "with conditions provided" do

        before do
          Mongoid::Persistence::RemoveAll.expects(:new).with(
            Person,
            { :validate => false, :safe => true },
            { :title => "Sir" }
          ).returns(command)
          command.expects(:persist).returns(true)
        end

        it "sends the safe mode option to the command" do
          Person.safely.delete_all(:conditions => { :title => "Sir" })
        end
      end
    end

    describe "#destroy_all" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => true }
        ).returns(command)
        command.expects(:persist).returns(person)
        Person.expects(:all).returns([ person ])
      end

      context "without onditions provided" do

        it "sends the safe mode option to the command" do
          Person.safely.destroy_all
        end
      end

      context "with conditions provided" do

        it "sends the safe mode option to the command" do
          Person.safely.destroy_all(:conditions => { :title => "Sir" })
        end
      end
    end
  end
end
