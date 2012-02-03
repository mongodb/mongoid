require "spec_helper"

describe Mongoid::Safety do

  describe ".clear" do

    context "when options exist on the current thread" do

      before do
        Band.safely(true)
      end

      let!(:cleared) do
        described_class.clear
      end

      it "remove the options from the current thread" do
        described_class.options.should be_false
      end

      it "returns true" do
        cleared.should be_true
      end
    end

    context "when options do not exist on the current thread" do

      it "returns true" do
        described_class.clear.should be_true
      end
    end
  end

  describe ".options" do

    context "when configured to persist in safe mode" do

      before do
        Mongoid.persist_in_safe_mode = true
      end

      after do
        Mongoid.persist_in_safe_mode = false
      end

      context "when options exist on the current thread" do

        before do
          Band.safely(w: 2)
        end

        after do
          described_class.clear
        end

        it "returns the options" do
          described_class.options.should eq(w: 2)
        end
      end

      context "when there are no options on the current thread" do

        it "returns the global configuration" do
          described_class.options.should be_true
        end
      end
    end

    context "when safe mode is not configured" do

      before do
        Mongoid.persist_in_safe_mode = false
      end

      it "returns the global configuration" do
        described_class.options.should be_false
      end
    end
  end

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
            }.to raise_error(Moped::Errors::OperationFailure)
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
            }.to raise_error(Moped::Errors::OperationFailure)
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
            }.to raise_error(Moped::Errors::OperationFailure)
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
            }.to raise_error(Moped::Errors::OperationFailure)
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
              }.to raise_error(Moped::Errors::OperationFailure)
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
              }.to raise_error(Moped::Errors::OperationFailure)
            end
          end
        end
      end
    end
  end
end
