require 'spec_helper'

describe Mongoid::Relations::Touch do
  describe '.cascade_touch!' do
    let(:klass) do
      Class.new.tap { |c| c.send(:include, Mongoid::Document) }
    end

    context "when touch option is provided" do
      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          name: :post,
          touch: true,
          relation: Mongoid::Relations::Referenced::In
        )
      end

      let!(:touch) do
        klass.touch(metadata)
      end

      it 'adds the action to the touches' do
        klass.touches.should include('post')
      end

      it "returns self" do
        touch.should eq(klass)
      end
    end

    context "when no touch option is provided" do
      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          name: :post,
          relation: Mongoid::Relations::Referenced::In
        )
      end

      let!(:touch) do
        klass.touch(metadata)
      end

      it 'does not add the action to the touches' do
        klass.touches.should_not include('post')
      end

      it "returns self" do
        touch.should eq(klass)
      end
    end
  end

  describe "touch" do
    before do
      Account.send(:include, Mongoid::Timestamps::Updated)
    end

    let(:account) {
      a = Account.create!(:name => 'cyril')
      a.updated_at = 1.day.ago.utc
      a.save!
      a
    }

    let(:alert) {
      al = account.alerts.create
      al.updated_at = 1.hour.ago.utc
      al.save!
      al
    }

    context "on belongs_to" do
      before do
        Mongoid.logger = Logger.new($stdout)
      end
      context "with Mongoid::Timestamps::Updated include" do
        before do
          Alert.send :include, Mongoid::Timestamps::Updated
        end

        context "with a touch option on belongs_to association" do
          before do
            Alert.belongs_to :account, :touch => true
          end
          it 'touch address on account save' do
            alert.touch
            alert.updated_at.should be_within(1).of(account.updated_at)
          end
        end

        context "without touch option on belongs_to association" do
          before do
            Alert.belongs_to :account, :touch => false
          end
          it 'touch address on account save' do
            alert.touch
            alert.updated_at.should_not be_within(1).of(account.updated_at)
          end
        end
      end

      context "withtout Mongoid::Timestamps::Updated include" do
      end
    end


    context "with a touch option on a model with Timestamps include" do

      before do
      end
    end
  end
end
