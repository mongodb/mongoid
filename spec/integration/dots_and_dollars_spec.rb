# frozen_string_literal: true

require "spec_helper"

describe "Dots and Dollars" do
  min_server_version '5.0'

  before(:all) do
    class DADMUser
      include Mongoid::Document
      field :"first.last", type: String, default: "Neil.Shweky"
      field :"$_amount", type: Integer, default: 0
      field :"$a.b", type: Boolean, default: true
    end
  end

  let!(:user) { DADMUser.create! }

  describe "accessing the fields" do

    context "when using the field getters" do

      context "on dotted fields" do
        it "gets the right value" do
          expect(user.send(:"first.last")).to eq("Neil.Shweky")
        end
      end

      context "on dollared fields" do
        it "gets the right value" do
          expect(user.send(:"$_amount")).to eq(0)
        end
      end

      context "on dotted and dollared fields" do
        it "gets the right value" do
          expect(user.send(:"$a.b")).to be true
        end
      end
    end

    context "when using the read_attribute" do

      context "on dotted fields" do
        it "gets the right value" do
          expect(user.read_attribute("first.last")).to eq("Neil.Shweky")
        end
      end

      context "on dollared fields" do
        it "gets the right value" do
          expect(user.read_attribute("$_amount")).to eq(0)
        end
      end

      context "on dotted and dollared fields" do
        it "gets the right value" do
          expect(user.read_attribute("$a.b")).to be true
        end
      end
    end

    context "when using the field setters" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user.send(:"first.last=", "Nissim.Shweky")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user.send(:"$_amount=", 1)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user.send(:"$a.b=", false)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end

    context "when updating via write_attribute" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user.write_attribute("first.last", "Nissim.Shweky")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user.write_attribute("$_amount", 1)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user.write_attribute("$a.b", false)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end

    context "when updating via update_attribute" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user.update_attribute("first.last", "Nissim.Shweky")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user.update_attribute("$_amount", 1)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user.update_attribute("$a.b", false)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end

    context "when updating via update_attributes!" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user.update_attributes!("first.last": "Nissim.Shweky")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user.update_attributes!("$_amount": 1)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user.update_attributes!("$a.b": false)
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end

    context "when updating via []=" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user[:"first.last"] = "Nissim.Shweky"
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user[:"$_amount"] = 1
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user[:"$a.b"] = false
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end

    context "when updating via remove_attribute" do

      context "on dotted fields" do
        it "raises an error" do
          expect do
            user.remove_attribute("first.last")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dollared fields" do
        it "raises an error" do
          expect do
            user.remove_attribute("$_amount")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end

      context "on dotted and dollared fields" do
        it "raises an error" do
          expect do
            user.remove_attribute("$a.b")
          end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
        end
      end
    end
  end

  describe "persisting to the db" do

    context "when saving to the db" do

      let(:user) { DADMUser.new }

      it "the save succeeds" do
        expect do
          user.save!
        end.to_not raise_error
      end
    end

    context "when retrieving it from the db" do

      let(:from_db) { DADMUser.first }

      it "has the fields populated correctly" do
        expect(from_db.attributes["first.last"]).to eq("Neil.Shweky")
        expect(from_db.attributes["$_amount"]).to eq(0)
        expect(from_db.attributes["$a.b"]).to eq(true)
      end
    end
  end

  describe "querying that field" do

    context "when attempting to query a dotted field" do

      let(:queried) do
        DADMUser.where("first.last": "Neil.Shweky").first
      end

      it "does not work" do
        expect(queried).to be nil
      end
    end

    context "when attempting to query a dollared field" do

      let(:queried) do
        DADMUser.where("$_amount": 0).first
      end

      it "raise an error" do
        expect do
          queried
        end.to raise_error(Mongo::Error::OperationFailure)
      end
    end
  end
end
