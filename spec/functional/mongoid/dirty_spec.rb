require "spec_helper"

describe Mongoid::Dirty do

  before do
    [ Person, Preference ].each(&:delete_all)
  end

  context "when modifying a many to many key" do

    let!(:person) do
      Person.create(:ssn => "342-89-2439")
    end

    let!(:preference) do
      Preference.create(:name => "dirty")
    end

    before do
      person.update_attributes(:preference_ids => [ preference.id ])
    end

    it "records the foreign key dirty changes" do
      person.previous_changes.should eq({
        "preference_ids" => [[], [ preference.id ]], "version" => [1, 2]
      })
    end
  end

  context "when accessing an array field" do

    let!(:person) do
      Person.create(:ssn => "342-89-2431")
    end

    let(:from_db) do
      Person.find(person.id)
    end

    context "when the field is not changed" do

      before do
        from_db.preference_ids
      end

      it "does not get marked as dirty" do
        from_db.changes["preference_ids"].should be_nil
      end
    end
  end

  context "when reloading an unchanged document" do

    let!(:person) do
      Person.create(:ssn => "452-11-1092")
    end

    let(:from_db) do
      Person.find(person.id)
    end

    before do
      from_db.reload
    end

    it "clears the changed attributes" do
      from_db.changed_attributes.should be_empty
    end
  end

  context "when fields are getting changed" do

    let(:person) do
      Person.create(
        :title => "MC",
        :ssn => "234-11-2533",
        :some_dynamic_field => 'blah'
      )
    end

    before do
      person.title = "DJ"
      person.write_attribute(:ssn, "222-22-2222")
      person.some_dynamic_field = 'bloop'
    end

    it "marks the document as changed" do
      person.changed?.should == true
    end

    it "marks field changes" do
      person.changes.should == {
        "title" => [ "MC", "DJ" ],
        "ssn" => [ "234-11-2533", "222-22-2222" ],
        "some_dynamic_field" => [ "blah", "bloop" ]
      }
    end

    it "marks changed fields" do
      person.changed.should =~ [ "title", "ssn", "some_dynamic_field" ]
    end

    it "marks the field as changed" do
      person.title_changed?.should == true
    end

    it "stores previous field values" do
      person.title_was.should == "MC"
    end

    it "marks field changes" do
      person.title_change.should == [ "MC", "DJ" ]
    end

    it "allows reset of field changes" do
      person.reset_title!
      person.title.should == "MC"
      person.changed.should =~ [ "ssn", "some_dynamic_field", "title" ]
    end

    context "after a save" do

      before do
        person.save!
      end

      it "clears changes" do
        person.should_not be_changed
      end

      it "stores previous changes" do
        person.previous_changes["title"].should == [ "MC", "DJ" ]
        person.previous_changes["ssn"].should == [ "234-11-2533", "222-22-2222" ]
      end
    end

    context "when the previous value is nil" do

      before do
        person.score = 100
        person.reset_score!
      end

      it "removes the attribute from the document" do
        person.score.should be_nil
      end
    end
  end

  context "when accessing dirty attributes in callbacks" do

    context "when the document is persisted" do

      let!(:acolyte) do
        Acolyte.create(:name => "callback-test")
      end

      before do
        Acolyte.set_callback(:save, :after, :if => :callback_test?) do |doc|
          doc.changes.should == { "status" => [ nil, "testing" ] }
        end
      end

      after do
        Acolyte._save_callbacks.reject! do |callback|
          callback.kind == :after
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.update_attribute(:status, "testing")
      end
    end

    context "when the document is new" do

      let!(:acolyte) do
        Acolyte.new(:name => "callback-test")
      end

      before do
        Acolyte.set_callback(:save, :after, :if => :callback_test?) do |doc|
          doc.changes["name"].should == [ nil, "callback-test" ]
        end
      end

      after do
        Acolyte._save_callbacks.reject! do |callback|
          callback.kind == :after
        end
      end

      it "retains the changes until after all callbacks" do
        acolyte.save
      end
    end
  end

  context "when associations are getting changed" do

    let(:person) do
      person = Person.create(:addresses => [ Address.new ])
    end

    before do
      person.addresses = [ Address.new ]
    end

    it "should not set the association to nil when hitting the database" do
      person.setters.should_not == { "addresses" => nil }
    end
  end
end
