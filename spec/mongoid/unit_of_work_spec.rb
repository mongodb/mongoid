require "spec_helper"

describe Mongoid::UnitOfWork do

  describe ".unit_of_work" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when no options are provided" do

      context "when an exception is raised" do

        let(:person) do
          Person.new
        end

        before do
          Mongoid::IdentityMap.set(person)

          begin
            Mongoid.unit_of_work do
              raise RuntimeError
            end
          rescue
          end
        end

        let(:identity_map) do
          Mongoid::Threaded.identity_map
        end

        it "clears the identity map" do
          expect(identity_map).to be_empty
        end
      end

      context "when no exception is raised" do

        let(:person) do
          Person.new
        end

        before do
          Mongoid::IdentityMap.set(person)
          Mongoid.unit_of_work {}
        end

        let(:identity_map) do
          Mongoid::Threaded.identity_map
        end

        it "clears the identity map" do
          expect(identity_map).to be_empty
        end
      end
    end
  end

  context "with identity map enabled" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when options are provided" do

      context "when provided disable: :current" do

        it "disables the identity map on the current thread" do
          Mongoid.unit_of_work(disable: :current) do
            expect(Mongoid).to_not be_using_identity_map
          end
        end
      end

      context "when provided disable: :all" do

        let(:other) do
          Thread.new { "running new thread".inspect }
        end

        before do
          other.run
          Thread.current
        end

        after do
          Thread.kill(other)
        end

        it "disables the identity map on all threads" do
          Mongoid.unit_of_work(disable: :all) do
            Thread.list.each do |thread|
              expect(thread[:"[mongoid]:identity-map-enabled"]).to be_false
            end
          end
        end
      end

      context "when nested inside another unit of work" do

        let(:person) do
          Person.new
        end

        context "when documents exist in the identity map" do

          before do
            Mongoid::IdentityMap.set(person)
          end

          it "does not clear the map in the inner block" do
            Mongoid.unit_of_work do
              Mongoid.unit_of_work(disable: :current) do
                expect(Mongoid::IdentityMap[:people][person.id]).to eq(person)
              end
            end
          end

          it "clears the map after the block" do
            Mongoid.unit_of_work do
              Mongoid.unit_of_work(disable: :current) do
              end
            end
            expect(Mongoid::IdentityMap.get(Person, person.id)).to be_nil
          end
        end
      end
    end
  end

  context "when options are provided" do

    context "when provided enable: :current" do

      it "enables the identity map on the current thread for the duration of the query" do
        Mongoid.unit_of_work(enable: :current) do
          expect(Mongoid).to be_using_identity_map
        end
      end
    end

    context "when provided enable: :all" do

      let(:other) do
        Thread.new { "running new thread".inspect }
      end

      before do
        other.run
        Thread.current
      end

      after do
        Thread.kill(other)
      end

      it "enables the identity map on all threads for the duration of the query" do
        Mongoid.unit_of_work(enable: :all) do
          Thread.list.each do |thread|
            expect(thread[:"[mongoid]:identity-map-enabled"]).to be_true
          end
        end
      end
    end

  end

  describe ".using_identity_map?" do

    context "when configured to use the identity map" do

      before do
        Mongoid.identity_map_enabled = true
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      context "when disabled on the current thread" do

        before do
          Thread.current[:"[mongoid]:identity-map-enabled"] = false
        end

        it "returns false" do
          expect(Mongoid).to_not be_using_identity_map
        end
      end

      context "when enabled on the current thread" do

        before do
          Thread.current[:"[mongoid]:identity-map-enabled"] = true
        end

        it "returns true" do
          expect(Mongoid).to be_using_identity_map
        end
      end

      context "when no option is on the current thread" do

        before do
          Thread.current[:"[mongoid]:identity-map-enabled"] = nil
        end

        it "returns true" do
          expect(Mongoid).to be_using_identity_map
        end
      end
    end

    context "when not configured to use the identity map" do

      before do
        Mongoid.identity_map_enabled = false
      end

      it "returns false" do
        expect(Mongoid).to_not be_using_identity_map
      end
    end
  end
end
