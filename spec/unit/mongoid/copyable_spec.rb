require "spec_helper"

describe Mongoid::Copyable do

  before do
    Person.delete_all
  end

  [ :clone, :dup ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.new(:title => "Sir", :ssn => "234-33-3123", :version => 4)
      end

      let!(:address) do
        person.addresses.build(:street => "Bond")
      end

      let!(:name) do
        person.build_name(:first_name => "Judy")
      end

      let!(:posts) do
        person.posts.build(:title => "testing")
      end

      let!(:game) do
        person.build_game(:name => "Tron")
      end

      context "when the document is new" do

        context "when versions exist" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { :number => 1 } ]
          end

          it "returns a new document" do
            copy.should_not be_persisted
          end

          it "has an id" do
            copy.id.should_not be_nil
          end

          it "has a different id from the original" do
            copy.id.should_not == person.id
          end

          it "does not copy the versions" do
            copy[:versions].should be_nil
          end

          it "resets the document version" do
            copy.version.should eq(1)
          end

          it "returns a new instance" do
            copy.should_not be_eql(person)
          end

          it "copys embeds many documents" do
            copy.addresses.should == person.addresses
          end

          it "creates new embeds many instances" do
            copy.addresses.should_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            copy.name.should == person.name
          end

          it "creates a new embeds one instance" do
            copy.name.should_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            copy.posts.should be_empty
          end

          it "does not copy references one documents" do
            copy.game.should be_nil
          end

          Mongoid::Copyable::COPYABLES.each do |name|

            it "dups #{name}" do
              copy.instance_variable_get(name).should_not
                be_eql(person.instance_variable_get(name))
            end
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save
            end

            it "persists the attributes" do
              reloaded.title.should == "Sir"
            end

            it "persists the embeds many relation" do
              reloaded.addresses.should == person.addresses
            end

            it "persists the embeds one relation" do
              reloaded.name.should == person.name
            end
          end
        end
      end

      context "when the document is not new" do

        before do
          person.new_record = false
        end

        context "when versions exist" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { :number => 1 } ]
          end

          it "returns a new document" do
            copy.should_not be_persisted
          end

          it "has an id" do
            copy.id.should_not be_nil
          end

          it "has a different id from the original" do
            copy.id.should_not == person.id
          end

          it "does not copy the versions" do
            copy[:versions].should be_nil
          end

          it "returns a new instance" do
            copy.should_not be_eql(person)
          end

          it "copys embeds many documents" do
            copy.addresses.should == person.addresses
          end

          it "creates new embeds many instances" do
            copy.addresses.should_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            copy.name.should == person.name
          end

          it "creates a new embeds one instance" do
            copy.name.should_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            copy.posts.should be_empty
          end

          it "does not copy references one documents" do
            copy.game.should be_nil
          end

          Mongoid::Copyable::COPYABLES.each do |name|

            it "dups #{name}" do
              copy.instance_variable_get(name).should_not
                be_eql(person.instance_variable_get(name))
            end
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save
            end

            it "persists the attributes" do
              reloaded.title.should == "Sir"
            end

            it "persists the embeds many relation" do
              reloaded.addresses.should == person.addresses
            end

            it "persists the embeds one relation" do
              reloaded.name.should == person.name
            end
          end
        end
      end
    end
  end
end
