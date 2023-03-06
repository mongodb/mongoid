# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Marshalable do
  describe "Marshal.dump" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "does not error" do
      expect {
        Marshal.dump(criteria)
      }.not_to raise_error
    end
  end

  describe "Marshal.load" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    it "loads the proper attributes" do
      expect(Marshal.load(Marshal.dump(criteria))).to eq(criteria)
    end

    context "when it receives driver mongo1x" do
      let(:dump) { Marshal.dump(criteria) }

      before do
        expect_any_instance_of(Mongoid::Criteria).to receive(:marshal_dump).and_wrap_original do |m, *args|
          data = m.call(*args)
          data[1] = :mongo1x
          data
        end
      end

      it "raises an error" do
        expect do
          Marshal.load(dump)
        end.to raise_error(NotImplementedError, /Mongoid no longer supports marshalling with driver version 1.x./)
      end
    end
  end
end
