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
        expect(Person.readonly_attributes.to_a).to eq([ "title" ])
      end
    end

    context "when providing multiple fields" do

      before do
        Person.attr_readonly :title, :terms
      end

      it "adds the fields to readonly attributes" do
        expect(Person.readonly_attributes.to_a).to eq([ "title", "terms" ])
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
        expect(person.title).to eq("sir")
      end

      it "sets subsequent readonly values" do
        expect(person.terms).to be true
      end

      it "persists the first readonly value" do
        expect(person.reload.title).to eq("sir")
      end

      it "persists subsequent readonly values" do
        expect(person.reload.terms).to be true
      end
    end

    context "when updating an existing readonly field" do

      before do
        Person.attr_readonly :title, :terms, :score
      end

      let(:person) do
        Person.create(title: "sir", terms: true, score: 1)
      end

      context "when updating via the setter" do

        before do
          person.title = "mr"
          person.save
        end

        it "does not update the field" do
          expect(person.title).to eq("sir")
        end

        it "does not persist the changes" do
          expect(person.reload.title).to eq("sir")
        end
      end

      context "when updating via inc" do

        context 'with single field operation' do
          it "raises an error " do
            expect {
              person.inc(score: 1)
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end

        context 'with multiple fields operation' do
          it "raises an error " do
            expect {
              person.inc(score: 1, age: 1)
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end
      end

      context "when updating via bit" do

        context 'with single field operation' do
          it "raises an error " do
            expect {
              person.bit(score: { or: 13 })
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end

        context 'with multiple fields operation' do
          it "raises an error " do
            expect {
              person.bit(
                age: { and: 13 }, score: { or: 13 }, inte: { and: 13, or: 10 }
              )
            }.to raise_error(Mongoid::Errors::ReadonlyAttribute)
          end
        end
      end

      context "when updating via []=" do

        before do
          person[:title] = "mr"
          person.save
        end

        it "does not update the field" do
          expect(person.title).to eq("sir")
        end

        it "does not persist the changes" do
          expect(person.reload.title).to eq("sir")
        end
      end

      context "when updating via write_attribute" do

        before do
          person.write_attribute(:title, "mr")
          person.save
        end

        it "does not update the field" do
          expect(person.title).to eq("sir")
        end

        it "does not persist the changes" do
          expect(person.reload.title).to eq("sir")
        end
      end

      context "when updating via update_attributes" do

        before do
          person.update_attributes(title: "mr")
          person.save
        end

        it "does not update the field" do
          expect(person.title).to eq("sir")
        end

        it "does not persist the changes" do
          expect(person.reload.title).to eq("sir")
        end
      end

      context "when updating via update_attributes!" do

        before do
          person.update_attributes!(title: "mr")
          person.save
        end

        it "does not update the field" do
          expect(person.title).to eq("sir")
        end

        it "does not persist the changes" do
          expect(person.reload.title).to eq("sir")
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
