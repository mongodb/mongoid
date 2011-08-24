require "spec_helper"

describe Mongoid::Callbacks do

  before do
    ValidationCallback.delete_all
    ParentDoc.delete_all
  end

  context "callback on valid?" do
    it 'should go in all validation callback in good order' do
      shin = ValidationCallback.new
      shin.valid?
      shin.history.should == [:before_validation, :validate, :after_validation]
    end
  end

  context "when creating child documents in callbacks" do

    let(:parent) do
      ParentDoc.new
    end

    before do
      parent.save
    end

    it "does not duplicate the child documents" do
      parent.child_docs.create(:position => 1)
      ParentDoc.find(parent.id).child_docs.size.should == 1
    end
  end

  context "when callbacks cancel persistence" do

    let(:address) do
      Address.new(:street => "123 Sesame")
    end

    context "when creating a document" do

      let(:person) do
        Person.new(:mode => :prevent_save, :title => "Associate", :addresses => [ address ])
      end

      it "fails to save" do
        person.should be_valid
        person.save.should == false
      end

      it "is a new record" do
        person.should be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        person.should be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        address.should be_changed
        expect { person.save }.not_to change { address.changed? }
      end

    end

    context "when updating a document" do

      let(:person) do
        Person.create.tap do |person|
          person.attributes = {
            :mode => :prevent_save,
            :title => "Associate",
            :addresses => [ address ]
          }
        end
      end

      after do
        Person.delete_all
      end

      it "#save returns false" do
        person.should be_valid
        person.save.should == false
      end

      it "is a not a new record" do
        person.should_not be_a_new_record
        expect { person.save }.not_to change { person.new_record? }
      end

      it "is left dirty" do
        person.should be_changed
        expect { person.save }.not_to change { person.changed? }
      end

      it "child documents are left dirty" do
        address.should be_changed
        expect { person.save }.not_to change { address.changed? }
      end
    end
  end
end
