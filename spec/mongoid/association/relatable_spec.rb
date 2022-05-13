# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Relatable do

  context "anonymous classes" do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        embeds_many :addresses
      end
    end

    it "allows relations" do
      expect { klass }.to_not raise_error
      expect { klass.new.addresses }.to_not raise_error
      expect(klass.new.addresses.build).to be_a Address
    end
  end
end
