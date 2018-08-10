# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Module do

  describe "#re_define_method" do

    context "when the method already exists" do

      class Smoochy
        def sing
          "singing"
        end
      end

      before do
        Smoochy.re_define_method("sing") do
          "singing again"
        end
      end

      it "redefines the existing method" do
        expect(Smoochy.new.sing).to eq("singing again")
      end
    end

    context "when the method does not exist" do

      class Rhino
      end

      before do
        Rhino.re_define_method("sing") do
          "singing"
        end
      end

      it "redefines the existing method" do
        expect(Rhino.new.sing).to eq("singing")
      end
    end
  end
end
