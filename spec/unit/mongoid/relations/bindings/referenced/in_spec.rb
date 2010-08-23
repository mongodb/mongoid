require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::In do

  let(:klass) do
    Mongoid::Relations::Bindings::Referenced::In
  end

  let(:base) do
    Post.new
  end

  let(:target) do
    Person.new
  end

  describe "#bind" do

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :post,
        :inverse_setter => "post="
      )
    end

    let(:binding) do
      klass.new(base, target, metadata)
    end

    context "when the base is bindable" do

      before do
        binding.expects(:bindable?).with(base).returns(true)
      end

      it "sets the base and base id on the target" do
        base.expects(:send).with("person_id=", target.id)
        target.expects(:send).with("post=", base)
        binding.bind
      end
    end
  end

  describe "#unbind" do

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :post,
        :inverse_setter => "post="
      )
    end

    let(:binding) do
      klass.new(base, target, metadata)
    end

    context "when the target is unbindable" do

      before do
        binding.expects(:unbindable?).with(base).returns(true)
      end

      it "removes the foreign key and inverse from the target" do
        base.expects(:send).with("person_id=", nil)
        target.expects(:send).with("post=", nil)
        binding.unbind
      end
    end
  end
end
