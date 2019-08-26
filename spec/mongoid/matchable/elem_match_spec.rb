# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::ElemMatch do

  let(:attribute) {[{"a" => 1, "b" => 2}, {"a" => 2, "b" => 2}, {"a" => 3, "b" => 1}]}
  let(:matcher) do
    described_class.new(attribute)
  end

  describe "#_matches?" do

    context "when the attribute is not an array" do

      let(:attribute) {"string"}

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 1})).to be false
      end
    end

    context "when the $elemMatch is not a hash" do

      let(:attribute) {"string"}

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => [])).to be false
      end
    end

    context "when there is a sub document that matches the criteria" do

      it "returns true" do
        expect(matcher._matches?("$elemMatch" => {"a" => 1})).to be true
      end

      context "when evaluating multiple fields of the subdocument" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => 1, "b" => 2})).to be true
        end

        context "when the $elemMatch document keys are out of order" do

          it "returns true" do
            expect(matcher._matches?("$elemMatch" => {"b" => 2, "a" => 1})).to be true
          end
        end
      end

      context "when using other operators that match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$in" => [1]}, "b" => {"$gt" => 1}})).to be true
        end
      end

      context "when using a $not operator that matches" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$not" => 4}})).to be true
        end
      end
    end

    context "when using symbols and a :$not operator that matches" do
      it "returns true" do
        expect(matcher._matches?(:$elemMatch => {"a" => {:$not => 4}})).to be true
      end
    end

    context "when there is not a sub document that matches the criteria" do

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 10})).to be false
      end

      context "when evaluating multiple fields of the subdocument" do

        it "returns false" do
          expect(matcher._matches?("$elemMatch" => {"a" => 1, "b" => 3})).to be false
        end
      end

      context "when using other operators that do not match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$in" => [1]}, "b" => {"$gt" => 10}})).to be false
        end
      end

      context "when using a $not operator that does not match" do

        it "returns true" do
          expect(matcher._matches?("$elemMatch" => {"a" => {"$not" => 1}})).to be true
        end
      end
    end

    context "when using a criteria that matches partially but not a single sub document" do

      it "returns false" do
        expect(matcher._matches?("$elemMatch" => {"a" => 3, "b" => 2})).to be false
      end
    end

    context "when nesting queries" do
      context "and using nested and" do
        it "returns true for nested eq" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => {:$eq => 1}},
                {:b => {:$eq => 2}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns true for raw value" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => 1},
                {:b => 2}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false when partially false" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => {:$eq => 1}},
                {:b => {:$eq => 20}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns false when partially false on raw values" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => 1},
                {:b => 20}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns false when fully false" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => {:$eq => 10}},
                {:b => {:$eq => 20}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns false when fully false on raw values" do
          query = {
            :$elemMatch => {
              :$and => [
                {:a => 10},
                {:b => 20}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end
      end

      context "and using nested or" do
        it "returns true" do
          query = {
            :$elemMatch => {
              :$or => [
                {:a => {:$eq => 1}},
                {:b => {:$eq => 1}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns true on raw values" do
          query = {
            :$elemMatch => {
              :$or => [
                {:a => 1},
                {:b => 1}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false" do
          query = {
            :$elemMatch => {
              :$or => [
                {:a => {:$eq => 10}},
                {:b => {:$eq => 10}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns false on raw values" do
          query = {
            :$elemMatch => {
              :$or => [
                {:a => 10},
                {:b => 10}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end
      end

      context "and using nested nor" do
        it "returns true" do
          query = {
            :$elemMatch => {
              :$nor => [
                {:a => {:$eq => 1}},
                {:b => {:$eq => 2}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns true on raw values" do
          query = {
            :$elemMatch => {
              :$nor => [
                {:a => 1},
                {:b => 2}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false" do
          query = {
            :$elemMatch => {
              :$nor => [
                {:a => {:$lt => 10}},
                {:b => {:$lt => 10}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end
      end

      context "and using nested not" do
        it "returns true" do
          query = {
            :$elemMatch => {
              :not => {
                :$nor => [
                  {:a => {:$lt => 10}},
                  {:b => {:$lt => 10}}
                ]
              }
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false" do
          query = {
            :$elemMatch => {
              :$not => {
                :$or => [
                  {:a => {:$lt => 10}},
                  {:b => {:$lt => 10}}
                ]
              }
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns false for a non nested value" do
          query = {
            :$elemMatch => {
              :$not => {
                :a => {:$lt => 10},
              }
            }
          }
          expect(matcher._matches?(query)).to be false
        end
      end

      context "and using multiple nested statements" do
        let(:attribute) {[{"a" => 1, "b" => 1}, {"a" => 1, "b" => 1}, {"a" => 3, "b" => 3}]}

        it "returns true" do
          query = {
            :$elemMatch => {
              :b => 3,
              :$or => [
                {:a => {:$ne => 1}},
                {:b => {:$ne => 1}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false" do
          query = {
            :$elemMatch => {
              :b => 1,
              :$or => [
                {:a => {:$gt => 5}},
                {:b => {:$lt => 1}}
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end

        it "returns true on two level deep nesting with not" do
          query = {
            :$elemMatch => {
              :$or => [
                {
                  :$not => {:a => {:$lt => 10}}
                },
                {
                  :$and => [
                    {:a => {:$eq => 3}},
                    {:b => {:$eq => 3}}
                  ]
                }
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns true on two level deep nesting with not as the matching statement" do
          query = {
            :$elemMatch => {
              :$or => [
                {
                  :$not => {:a => {:$gt => 10}}
                },
                {
                  :$and => [
                    {:a => {:$eq => 10}},
                    {:b => {:$eq => 10}}
                  ]
                }
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns true on multiple level deep nesting with not as the matching statement" do
          query = {
            :$elemMatch => {
              :$or => [
                {
                  :$not => {
                    :$not => {
                      :$not => {
                        :$not => {
                          :$or => [
                            {:a => {:$eq => 1}},
                            {:b => {:$eq => 1}}
                          ]
                        }
                      }
                    }
                  }
                },
                {
                  :b => {:$eq => 10}
                }
              ]
            }
          }
          expect(matcher._matches?(query)).to be true
        end

        it "returns false on multiple level deep nesting with not as the matching statement" do
          query = {
            :$elemMatch => {
              :$or => [
                {
                  :$not => {
                    :$not => {
                      :$not => {
                        :$not => {
                          :$not => {
                            :$not => {
                              :$not => {
                                :$or => [
                                  {:a => {:$lt => 10}},
                                  {:b => {:$lt => 10}}
                                ]
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                },
                {
                  :b => {:$eq => 10}
                }
              ]
            }
          }
          expect(matcher._matches?(query)).to be false
        end
      end
    end
  end
end
