require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::One do

  let(:klass) do
    Mongoid::Relations::Bindings::Referenced::One
  end

  let(:base) do
    Person.new
  end

  let(:target) do
    Post.new
  end

  describe "#bind" do

    let(:metadata) do
      stub(
        :extension? => false,
        :foreign_key_setter => "person_id=",
        :inverse => :person,
        :inverse_setter => "person="
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
        target.expects(:send).with("person_id=", base.id)
        target.expects(:send).with("person=", base)
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
        binding.expects(:unbindable?).with(target).returns(true)
      end

      it "removes the foreign key and inverse from the target" do
        target.expects(:send).with("person_id=", nil)
        target.expects(:send).with("post=", nil)
        binding.unbind
      end
    end
  end
end
