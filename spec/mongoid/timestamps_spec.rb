# frozen_string_literal: true

require "spec_helper"
require_relative './timestamps_spec_models'

describe Mongoid::Timestamps do

  describe ".included" do

    let(:document) do
      Dokument.new
    end

    let(:fields) do
      Dokument.fields
    end

    let(:time_zone) { "Pacific Time (US & Canada)" }

    time_zone_override "Pacific Time (US & Canada)"

    before do
      document.run_callbacks(:create)
      document.run_callbacks(:save)
    end

    it "adds created_at to the document" do
      expect(fields["created_at"]).to_not be_nil
    end

    it "adds updated_at to the document" do
      expect(fields["updated_at"]).to_not be_nil
    end

    it "forces the created_at timestamps to UTC" do
      expect(document.created_at).to be_within(10).of(Time.now.utc)
    end

    it "forces the updated_at timestamps to UTC" do
      expect(document.updated_at).to be_within(10).of(Time.now.utc)
    end

    it "sets the created_at to the correct time zone" do
      expect(document.created_at.time_zone.name).to eq(time_zone)
    end

    it "sets the updated_at to the correct time zone" do
      expect(document.updated_at.time_zone.name).to eq(time_zone)
    end

    it "ensures created_at equals updated_at on new records" do
      expect(document.updated_at).to eq(document.created_at)
    end
  end

  context "when the document has not changed" do

    let(:document) do
      Dokument.instantiate(Dokument.new.attributes)
    end

    before do
      document.new_record = false
    end

    it "does not run the update callbacks" do
      expect(document).to receive(:updated_at=).never
      document.save!
    end
  end

  context "when the document has changed with updated_at specified" do

    let(:document) do
      Dokument.create(created_at: Time.now.utc)
    end

    let(:expected_updated_at) do
      DateTime.parse("2001-06-12")
    end

    before do
      document.updated_at = expected_updated_at
    end

    it "does not set updated at" do
      document.save!
      expect(document.reload.updated_at).to be == expected_updated_at
    end
  end

  context "when the document is created" do

    let!(:document) do
      Dokument.create!
    end

    it "runs the update callbacks" do
      expect(document.updated_at).to eq(document.created_at)
    end
  end

  context "when only embedded documents have changed" do

    let!(:document) do
      Dokument.create!(updated_at: 2.days.ago)
    end

    let!(:address) do
      document.addresses.create!(street: "Karl Marx Strasse")
    end

    let!(:updated_at) do
      document.updated_at
    end

    before do
      address.number = 1
      document.save!
    end

    it "updates the root document updated at" do
      expect(document.updated_at).to be_within(1).of(Time.now)
    end
  end

  # This section of tests describes the behavior of the updated_at field for
  # different updates on referenced associations, as outlined in PR #5219.
  describe "updated_at attribute" do
    let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

    let(:update_time) do
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
    end

    after do
      Timecop.return
    end

    context "when touch: true" do
      let(:user) { TimestampsSpec::Touch::User.create! }
      let(:address) { TimestampsSpec::Touch::Address.create! }
      let(:account) { TimestampsSpec::Touch::Account.create! }
      let(:pet) { TimestampsSpec::Touch::Pet.create! }

      before do
        [user, address, account, pet]
        update_time
      end

      context "when HABTM association" do

        context "when updating the association itself" do
          before do
            user.update(addresses: [address])
          end

          it "updates the timestamps correctly" do
            pending "MONGOID-4953"
            user.updated_at.should == update_time
            address.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            pending "MONGOID-4953"
            user.reload.updated_at.should == update_time
            address.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            user.update(address_ids: [address.id])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            address.updated_at.should == start_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            address.reload.updated_at.should == start_time
          end
        end
      end

      context "when has_many association" do

        context "when updating the association itself" do
          before do
            user.update(accounts: [account])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            account.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            account.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            user.update(account_ids: [account.id])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            account.updated_at.should == start_time
          end

          # The Account object's updated_at is updated in the database but not
          # locally, since, in this case, the Account object is not passed into
          # the update function, so the Account object updated locally is not
          # the same as the one that we have locally here.
          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            account.reload.updated_at.should == update_time
          end
        end
      end

      context "when belongs_to association; on has_many" do

        context "when updating the association itself" do
          before do
            account.update(user: user)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            account.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            account.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            account.update(user_id: user.id)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            account.updated_at.should == update_time
          end

          # The User object's updated_at is updated in the database but not
          # locally, since, in this case, the User object is not passed into
          # the update function, so the User object updated locally is not
          # the same as the one that we have locally here.
          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            account.reload.updated_at.should == update_time
          end
        end
      end

      context "when has_one association" do

        context "when updating the association itself" do
          before do
            user.update(pet: pet)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            pet.reload.updated_at.should == update_time
          end
        end
      end

      context "when belongs_to association; on has_one" do

        context "when updating the association itself" do
          before do
            pet.update(user: user)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            pet.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            pet.update(user_id: pet.id)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            pet.reload.updated_at.should == update_time
          end
        end
      end
    end

    context "when touch: false" do
      let(:user) { TimestampsSpec::NoTouch::User.create! }
      let(:address) { TimestampsSpec::NoTouch::Address.create! }
      let(:account) { TimestampsSpec::NoTouch::Account.create! }
      let(:pet) { TimestampsSpec::NoTouch::Pet.create! }

      before do
        [user, address, account, pet]
        update_time
      end

      context "when HABTM association" do

        context "when updating the association itself" do
          before do
            user.update(addresses: [address])
          end

          it "updates the timestamps correctly" do
            pending "MONGOID-4953"
            user.updated_at.should == update_time
            address.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            pending "MONGOID-4953"
            user.reload.updated_at.should == update_time
            address.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            user.update(address_ids: [address.id])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == update_time
            address.updated_at.should == start_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == update_time
            address.reload.updated_at.should == start_time
          end
        end
      end

      context "when has_many association" do

        context "when updating the association itself" do
          before do
            user.update(accounts: [account])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            account.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            account.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            user.update(account_ids: [account.id])
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            account.updated_at.should == start_time
          end

          # The Account object's updated_at is updated in the database but not
          # locally, since, in this case, the Account object is not passed into
          # the update function, so the Account object updated locally is not
          # the same as the one that we have locally here.
          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            account.reload.updated_at.should == update_time
          end
        end
      end

      context "when belongs_to association; on has_many" do

        context "when updating the association itself" do
          before do
            account.update(user: user)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            account.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            account.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            account.update(user_id: user.id)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            account.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            account.reload.updated_at.should == update_time
          end
        end
      end

      context "when has_one association" do

        context "when updating the association itself" do
          before do
            user.update(pet: pet)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            pet.reload.updated_at.should == update_time
          end
        end
      end

      context "when belongs_to association; on has_one" do

        context "when updating the association itself" do
          before do
            pet.update(user: user)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            pet.reload.updated_at.should == update_time
          end
        end

        context "when updating the association's foreign key" do
          before do
            pet.update(user_id: pet.id)
          end

          it "updates the timestamps correctly" do
            user.updated_at.should == start_time
            pet.updated_at.should == update_time
          end

          it "updates the timestamps in the db correctly" do
            user.reload.updated_at.should == start_time
            pet.reload.updated_at.should == update_time
          end
        end
      end
    end
  end
end
