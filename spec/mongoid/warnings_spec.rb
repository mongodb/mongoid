# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Warnings do

  describe ".warn_*" do

    context "when calling a warn_* method" do

      let(:id) { :geo_haystack_deprecated }
      let(:message) do
        'The geoHaystack type is deprecated.'
      end

      before do
        warn_id = id
        Mongoid::Warnings.class_eval do
          instance_variable_set("@#{warn_id}", false)
        end
      end

      it "logs the warning" do
        expect_any_instance_of(Logger).to receive(:warn).once.with(message)
        Mongoid::Warnings.send("warn_#{id}")
      end

      it "logs the warning only once" do
        expect_any_instance_of(Logger).to receive(:warn).once.with(message)
        Mongoid::Warnings.send("warn_#{id}")
        Mongoid::Warnings.send("warn_#{id}")
      end
    end
  end
end
