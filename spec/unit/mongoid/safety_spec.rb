require "spec_helper"

describe Mongoid::Safety do

  describe ".safely" do

    context "default" do
      let(:proxy) do
        Person.safely
      end

      it "returns a safe proxy" do
        proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
      end

      it "proxies the class" do
        proxy.target.should == Person
      end

      it "defaults the safety options to true" do
        proxy.safety_options.should be_true
      end
    end

    context "with options" do
      let(:proxy) { Person.safely(:w => 2) }

      it "returns a safe proxy" do
        proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
      end

      it "proxies the class" do
        proxy.target.should == Person
      end

      it "stores the safety options" do
        proxy.safety_options.should == {:w => 2}
      end
    end
  end

  describe "#safely" do

    let(:person) do
      Person.new
    end

    context "default" do
      let(:proxy) do
        person.safely
      end

      it "returns a safe proxy" do
        proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
      end

      it "proxies the document" do
        proxy.target.should == person
      end

      it "defaults the safety value to true" do
        proxy.safety_options.should be_true
      end
    end

    context "with options" do
      let(:proxy) { person.safely(:w => 2) }

      it "returns a safe proxy" do
        proxy.should be_an_instance_of(Mongoid::Safety::Proxy)
      end

      it "proxies the class" do
        proxy.target.should == person
      end

      it "stores the safety options" do
        proxy.safety_options.should == {:w => 2}
      end
    end
  end

  shared_examples_for 'a safely persisting document instance' do

    describe "#delete" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.delete
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.delete(:safe => true)
        end
      end
    end

    describe "#destroy" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.destroy
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.destroy(:safe => true)
        end
      end
    end

    describe "#inc" do

      before do
        Mongoid::Modifiers::Inc.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(modifier)
        modifier.expects(:persist).with(:age, 5).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.inc(:age, 5)
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.inc(:age, 5, :safe => true)
        end
      end
    end

    describe "#insert" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.insert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.insert(:safe => true)
        end
      end
    end

    describe "#save!" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.insert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.insert(:safe => true)
        end
      end
    end

    describe "#update" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.update
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.update(:safe => true)
        end
      end
    end

    describe "#update_attributes" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.update_attributes(:title => "Sir")
        end
      end
    end

    describe "#update_attributes" do

      before do
        Mongoid::Persistence::Update.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(true)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.update_attributes!(:title => "Sir")
        end
      end
    end

    describe "#upsert" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(person)
      end

      context "without options provided" do

        it "sends the safe mode option to the command" do
          proxy.upsert
        end
      end

      context "with options provided" do

        it "sends the safe mode option to the command" do
          proxy.upsert(:safe => true)
        end
      end
    end
  end

  context "when proxying a document instance" do

    let(:command) do
      stub
    end

    let(:modifier) do
      stub
    end

    let(:person) do
      Person.new
    end

    context "when using default safety level" do
      let(:safety_options) { true }
      let(:proxy) { person.safely }

      it_behaves_like 'a safely persisting document instance'
    end

    context "when using specified safety level" do
      let(:safety_options) { {:w => true} }
      let(:proxy) { person.safely(safety_options) }

      it_behaves_like 'a safely persisting document instance'
    end

  end

  shared_examples_for 'a safely persisting class' do
    describe "#create" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        Person.expects(:new).returns(person)
        command.expects(:persist).returns(person)
      end

      context "without attributes provided" do

        it "sends the safe mode option to the command" do
          proxy.create
        end
      end

      context "with attributes provided" do

        it "sends the safe mode option to the command" do
          proxy.create(:title => "Sir")
        end
      end
    end

    describe "#create!" do

      before do
        Mongoid::Persistence::Insert.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        Person.expects(:new).returns(person)
        command.expects(:persist).returns(person)
      end

      context "without attributes provided" do

        it "sends the safe mode option to the command" do
          proxy.create!
        end
      end

      context "with attributes provided" do

        it "sends the safe mode option to the command" do
          proxy.create!(:title => "Sir")
        end
      end
    end

    describe "#delete_all" do

      context "without conditions provided" do

        before do
          Mongoid::Persistence::RemoveAll.expects(:new).with(
            Person,
            { :validate => false, :safe => safety_options },
            {}
          ).returns(command)
          command.expects(:persist).returns(true)
        end

        it "sends the safe mode option to the command" do
          proxy.delete_all
        end
      end

      context "with conditions provided" do

        before do
          Mongoid::Persistence::RemoveAll.expects(:new).with(
            Person,
            { :validate => false, :safe => safety_options },
            { :title => "Sir" }
          ).returns(command)
          command.expects(:persist).returns(true)
        end

        it "sends the safe mode option to the command" do
          proxy.delete_all(:conditions => { :title => "Sir" })
        end
      end
    end

    describe "#destroy_all" do

      before do
        Mongoid::Persistence::Remove.expects(:new).with(
          person,
          { :safe => safety_options }
        ).returns(command)
        command.expects(:persist).returns(person)
        Person.expects(:all).returns([ person ])
      end

      context "without onditions provided" do

        it "sends the safe mode option to the command" do
          proxy.destroy_all
        end
      end

      context "with conditions provided" do

        it "sends the safe mode option to the command" do
          proxy.destroy_all(:conditions => { :title => "Sir" })
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

    context "when using default safety level" do
      let(:safety_options) { true }
      let(:proxy) { Person.safely }
      it_behaves_like 'a safely persisting class'
    end

    context "when using a specified safety level" do
      let(:safety_options) { {:w => 2} }
      let(:proxy) { Person.safely(safety_options) }
      it_behaves_like 'a safely persisting class'
    end

  end
end
