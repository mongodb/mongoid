# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matcher do
  describe '.extract_attribute' do
    let(:raw_result) do
      described_class.extract_attribute(document, key)
    end

    let(:exists) { raw_result.first }
    let(:result) { raw_result.second }
    let(:expanded) { raw_result.last }

    context 'all scalars' do
      let(:document) do
        BSON::Document.new(foo: {bar: {foo: {bar: 2}}})
      end

      context 'leaf' do
        let(:key) { 'foo.bar.foo.bar' }

        it 'works' do
          exists.should be true
          result.should == 2
          expanded.should be false
        end
      end

      context 'non-leaf' do
        let(:key) { 'foo.bar' }

        it 'works' do
          exists.should be true
          result.should == {'foo' => {'bar' => 2}}
          expanded.should be false
        end
      end
    end

    context 'array leaf' do
      let(:document) do
        BSON::Document.new(foo: {bar: {foo: {bar: [2]}}})
      end

      context 'leaf' do
        let(:key) { 'foo.bar.foo.bar' }

        it 'works' do
          exists.should be true
          result.should == [2]
          expanded.should be false
        end
      end

      context 'non-leaf' do
        let(:key) { 'foo.bar' }

        it 'works' do
          exists.should be true
          result.should == {'foo' => {'bar' => [2]}}
          expanded.should be false
        end
      end
    end

    context 'array non-leaf' do
      let(:document) do
        BSON::Document.new(foo: [{bar: {foo: {bar: 2}}}])
      end

      context 'leaf' do
        let(:key) { 'foo.bar.foo.bar' }

        it 'works' do
          exists.should be true
          result.should == [2]
          expanded.should be true
        end
      end

      context 'non-leaf' do
        let(:key) { 'foo.bar' }

        it 'works' do
          exists.should be true
          result.should == ['foo' => {'bar' => 2}]
          expanded.should be true
        end
      end

      context 'missing' do
        let(:key) { 'foo.missing' }

        it 'works' do
          exists.should be false
          result.should == []
          expanded.should be true
        end
      end
    end

    context 'chain ends in document prematurely' do
      let(:document) do
        BSON::Document.new(foo: {hello: 'world'})
      end

      context 'leaf' do
        let(:key) { 'foo.bar.foo.bar' }

        it 'returns nil' do
          exists.should be false
          result.should be nil
          expanded.should be false
        end
      end

      context 'non-leaf' do
        let(:key) { 'foo.bar' }

        it 'returns nil' do
          exists.should be false
          result.should be nil
          expanded.should be false
        end
      end
    end

    context 'array index' do
      let(:document) do
        BSON::Document.new(
          foo: [
            {one: 1},
            {two: 2},
          ],
          bar: [3, 4],
        )
      end

      context 'hash leaf' do
        let(:key) { 'foo.1.two' }

        it 'works' do
          exists.should be true
          result.should == 2
          expanded.should be false
        end
      end

      context 'hash non-leaf' do
        let(:key) { 'foo.1' }

        it 'works' do
          exists.should be true
          result.should == {'two' => 2}
          expanded.should be false
        end
      end

      context 'scalar leaf' do
        let(:key) { 'bar.1' }

        it 'works' do
          exists.should be true
          result.should == 4
          expanded.should be false
        end
      end

      context 'index missing' do
        let(:key) { 'bar.2' }

        it 'works' do
          exists.should be false
          result.should be nil
          expanded.should be false
        end
      end

      context 'index missing followed by hash access' do
        let(:key) { 'bar.2.any' }

        it 'works' do
          exists.should be false
          result.should be nil
          expanded.should be false
        end
      end

      context 'non-sequential nested arrays' do
        let(:document) do
          BSON::Document.new(
            books: [
              {authors: [
                name: 'Steve',
              ]},
              {authors: [
                {name: 'Boris'},
                {name: 'Pasha'},
              ]},
            ],
          )
        end

        context 'hash leaf' do
          context 'one value' do
            let(:key) { 'books.0.authors.name' }

            it 'works' do
              exists.should be true
              result.should == ['Steve']
              expanded.should be true
            end
          end

          context 'multiple values' do
            let(:key) { 'books.1.authors.name' }

            it 'works' do
              exists.should be true
              result.should == %w(Boris Pasha)
              expanded.should be true
            end
          end
        end

        context 'hash non-leaf' do
          context 'one value' do
            let(:key) { 'books.0' }

            it 'works' do
              exists.should be true
              result.should == {'authors' => ['name' => 'Steve']}
              expanded.should be false
            end
          end

          context 'multiple values' do
            let(:key) { 'books.1' }

            it 'works' do
              exists.should be true
              result.should == {'authors' => [{'name' => 'Boris'}, {'name' => 'Pasha'}]}
              expanded.should be false
            end
          end
        end
      end
    end

    context 'sequential nested arrays' do
      let(:document) do
        BSON::Document.new(
          groups: [[1]],
        )
      end

      context 'numerically indexed leaf' do
        let(:key) { 'groups.0.0' }

        it 'works' do
          exists.should be true
          result.should == 1
          expanded.should be false
        end
      end

      context 'numerically indexed missing leaf' do
        let(:key) { 'groups.0.1' }

        it 'works' do
          exists.should be false
          result.should be nil
          expanded.should be false
        end
      end

      context 'hash path non-existent leaf' do
        let(:key) { 'groups.missing' }

        it 'works' do
          exists.should be false
          result.should == []
          expanded.should be true
        end
      end
    end
  end
end
