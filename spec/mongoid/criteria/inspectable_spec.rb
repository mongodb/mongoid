# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Criteria::Inspectable do

  describe "#inspect" do

    let(:criteria) do
      Person.where(:age.gt => 10, title: "Sir")
    end

    it "includes the selector" do
      expect(criteria.inspect).to include("selector")
    end

    it "includes the options" do
      expect(criteria.inspect).to include("options")
    end

    it "includes the class" do
      expect(criteria.inspect).to include("class")
    end

    it "includes the embedded flag" do
      expect(criteria.inspect).to include("embedded")
    end
  end
end
