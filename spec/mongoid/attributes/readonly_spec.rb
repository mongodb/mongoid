require "spec_helper"

describe Mongoid::Attributes::Readonly do

  describe ".attr_readonly" do

    after do
      Person.readonly_attributes.clear
    end

    context "when providing a single field" do

      before do
        Person.attr_readonly :title
      end

      it "adds the field to readonly attributes" do
        Person.readonly_attributes.to_a.should eq([ "title" ])
      end
    end

    context "when providing multiple fields" do

      before do
        Person.attr_readonly :title, :terms
      end

      it "adds the fields to readonly attributes" do
        Person.readonly_attributes.to_a.should eq([ "title", "terms" ])
      end
    end

    context "when creating a new document with a readonly field" do

      before do
        Person.attr_readonly :title, :terms
      end

      let(:person) do
        Person.create(title: "sir", terms: true)
      end

      it "sets the first readonly value" do
        person.title.should eq("sir")
      end

      it "sets subsequent readonly values" do
        person.terms.should be_true
      end

      it "persists the first readonly value" do
        person.reload.title.should eq("sir")
      end

      it "persists subsequent readonly values" do
        person.reload.terms.should be_true
      end
    end

    context "when updating an existing readonly field" do

      before do
        Person.attr_readonly :title, :terms
      end

      let(:person) do
        Person.create(title: "sir", terms: true)
      end

      context "when updating via the setter" do

        before do
          person.title = "mr"
          person.save
        end

        it "does not update the field" do
          person.title.should eq("sir")
        end

        it "does not persist the changes" do
          person.reload.title.should eq("sir")
        end
      end

      context "when updating via []=" do

        before do
          person[:title] = "mr"
          person.save
        end

        it "does not update the field" do
          person.title.should eq("sir")
        end

        it "does not persist the changes" do
          person.reload.title.should eq("sir")
        end
      end

      context "when updating via write_attribute" do

        before do
          person.write_attribute(:title, "mr")
          person.save
        end

        it "does not update the field" do
          person.title.should eq("sir")
        end

        it "does not persist the changes" do
          person.reload.title.should eq("sir")
        end
      end

      context "when updating via update_attributes" do

        before do
          person.update_attributes(title: "mr")
          person.save
        end

        it "does not update the field" do
          person.title.should eq("sir")
        end

        it "does not persist the changes" do
          person.reload.title.should eq("sir")
        end
      end

      context "when updating via update_attributes!" do

        before do
          person.update_attributes!(title: "mr")
          person.save
        end

        it "does not update the field" do
          person.title.should eq("sir")
        end

        it "does not persist the changes" do
          person.reload.title.should eq("sir")
        end
      end

      context "when updating via update_attribute" do

        it "raises an error" do
          expect {
            person.update_attribute(:title, "mr")
          }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
        end
      end

      context "when updating via remove_attribute" do

        it "raises an error" do
          expect {
            person.remove_attribute(:title)
          }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
        end
      end
    end
  end
end
