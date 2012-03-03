require "spec_helper"

describe Mongoid::Safety do

  describe ".safely" do

    context "when global safe mode is false" do

      before do
        Mongoid.persist_in_safe_mode = false
      end

      describe ".create" do

        before do
          Person.safely.create(ssn: "432-97-1111")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.safely.create(ssn: "432-97-1111")
            }.to raise_error(Mongo::OperationFailure)
          end
        end

        context "when using .safely(false)" do

          it "ignores mongodb error" do
            Person.safely(false).create(ssn: "432-97-1111").should be_true
          end

        end
      end

      describe ".create!" do

        before do
          Person.safely.create!(ssn: "432-97-1112")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.safely.create!(ssn: "432-97-1112")
            }.to raise_error(Mongo::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          it "raises the validation error" do
            expect {
              Account.safely.create!(name: "this name is way too long")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe ".save" do

        before do
          Person.safely.create(ssn: "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1113")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.safely.save
            }.to raise_error(Mongo::OperationFailure)
          end
        end
      end

      describe ".save!" do

        before do
          Person.safely.create!(ssn: "432-97-1114")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1114")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.safely.save!
            }.to raise_error(Mongo::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          let(:account) do
            Account.new(name: "this name is way too long")
          end

          it "raises the validation error" do
            expect {
              account.safely.save!
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  describe ".unsafely" do

    context "when global safe mode is true" do

      before do
        Mongoid.persist_in_safe_mode = true
      end

      after do
        Mongoid.persist_in_safe_mode = false
      end

      describe ".create" do

        before do
          Person.safely.create(ssn: "432-97-1111")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "fails silently" do
            Person.unsafely.create(ssn: "432-97-1111").should be_true
          end

          context "when creating again" do

            before do
              Person.unsafely.create(ssn: "432-97-1111")
            end

            it "uses defaults for subsequent requests" do
              expect {
                Person.create(ssn: "432-97-1111")
              }.to raise_error(Mongo::OperationFailure)
            end
          end
        end
      end

      describe ".save" do

        before do
          Person.safely.create(ssn: "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new
          end

          before do
            Person.create_indexes
          end

          it "fails silently" do
            person.unsafely.save(ssn: "432-97-1113").should be_true
          end

          context "when persisting again" do

            before do
              person.unsafely.save(ssn: "432-97-1113")
            end

            it "uses defaults for subsequent requests" do
              expect {
                Person.create(ssn: "432-97-1113")
              }.to raise_error(Mongo::OperationFailure)
            end
          end
        end
      end
    end
  end
end
