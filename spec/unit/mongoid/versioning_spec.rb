require "spec_helper"

describe Mongoid::Versioning do

  describe ".max_versions" do

    context "when provided an integer" do

      before do
        WikiPage.max_versions(10)
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should == 10
      end
    end

    context "when provided a string" do

      before do
        WikiPage.max_versions("10")
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should == 10
      end
    end
  end

  describe "#revise" do

    let(:criteria) do
      stub
    end

    let(:match) do
      stub
    end

    context "when a last version does not exist" do

      context "when versioning is new to the document" do

        let!(:page) do
          WikiPage.new(:title => "1")
        end

        before do
          WikiPage.expects(:where).with(:_id => page.id).returns(criteria)
          criteria.expects(:any_of).with({ :version => 1 }, { :version => nil }).returns(match)
          match.expects(:first).returns(nil)
          page.revise
        end

        it "does not add any versions" do
          page.versions.should be_empty
        end
      end

      context "when versioning has been in effect" do

        let!(:page) do
          WikiPage.new(:title => "1")
        end

        before do
          WikiPage.expects(:where).with(:_id => page.id).returns(criteria)
          criteria.expects(:any_of).with({ :version => 1 }, { :version => nil }).returns(match)
          match.expects(:first).returns(page)
          page.revise
        end

        it "adds the new version" do
          page.versions.should_not be_empty
        end
      end
    end

    context "when a last version exists" do

      let!(:page) do
        WikiPage.new(:title => "1", :version => 2)
      end

      let!(:first) do
        WikiPage.new(:title => "1", :version => 1)
      end

      before do
        WikiPage.expects(:where).with(:_id => page.id).returns(criteria)
        criteria.expects(:any_of).with({ :version => 2 }, { :version => nil }).returns(match)
        match.expects(:first).returns(first)
        page.revise
      end

      it "does not add any versions" do
        page.versions.size.should == 1
      end
    end

    context "when excluded fields change" do
      let(:page) do
        WikiPage.create
      end

      it "does not create a new version" do
        page.transient_property = 'a new value'
        page.versioned_attributes_changed?.should be_false
        page.expects(:revise).never
        page.save
      end
    end

    context "when creating a new version" do
      let(:page) do
        WikiPage.create(:transient_property => 'a temporary value',
                        :dynamic_attribute => 'dynamic')
      end

      before do
        page.title = "A New Title"
        page.save
      end

      it "does not include excluded attributes in the version" do
        page.versions.last.transient_property.should be_nil
      end

      it "includes dynamic attributes in the version" do
        page.versions.last.dynamic_attribute.should == 'dynamic'
      end
    end

    context "when excluded fields change" do
      let(:page) do
        WikiPage.create
      end

      before do
        page.new_record = false
      end

      it "does not create a new version" do
        page.transient_property = 'a new value'
        page.expects(:revise).never
        page.save
      end
    end

    context "when skipping versioning" do

      let(:person) do
        Person.new(:created_at => Time.now.utc)
      end

      before do
        person.new_record = false
      end

      it "does not add any versions" do
        person.expects(:revise).never
        person.versionless(&:save)
      end
    end
  end

  context "when the document has not changed" do

    let(:person) do
      Person.instantiate(:created_at => Time.now.utc)
    end

    before do
      person.new_record = false
    end

    it "does not run the versioning callbacks" do
      person.expects(:revise).never
      person.save
    end
  end

  describe "#revise!" do

    let(:criteria) do
      stub
    end

    let(:match) do
      stub
    end

    context "when a last version does not exist" do

      context "when versioning is new to the document" do

        let!(:page) do
          WikiPage.new(:title => "1")
        end
        subject { page }

        before do
          WikiPage.expects(:where).with(:_id => page.id).returns(criteria)
          criteria.expects(:any_of).with({ :version => 1 }, { :version => nil }).returns(match)
          match.expects(:first).returns(nil)
          page.expects(:save)
          page.revise!
        end

        its('versions.size') { should == 1 }
        its(:version) { should == 2 }
      end

      context "when versioning has been in effect" do

        let!(:page) do
          WikiPage.new(:title => "1")
        end
        subject { page }

        before do
          WikiPage.expects(:where).with(:_id => page.id).returns(criteria)
          criteria.expects(:any_of).with({ :version => 1 }, { :version => nil }).returns(match)
          match.expects(:first).returns(page)
          page.expects(:save)
          page.revise!
        end

        its('versions.size') { should == 1 }
        its(:version) { should == 2 }
      end
    end
  end

  describe "#versionless" do

    let(:person) do
      Person.new(:created_at => Time.now.utc)
    end

    context "when executing the block" do

      it "sets versionless to true" do
        person.versionless do |doc|
          doc.should be_versionless
        end
      end
    end

    context "when the block finishes" do

      it "sets versionless to false" do
        person.versionless
        person.should_not be_versionless
      end
    end
  end
end
