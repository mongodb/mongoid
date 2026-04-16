# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Builders do
  describe "#build_#\{name}" do
    let(:person) do
      Person.new
    end

    context 'when providing no attributes' do
      context 'when the relation is an embeds one' do
        let(:name) do
          person.build_name
        end

        it 'does not set a binding attribute' do
          expect(name[:binding]).to be_nil
        end
      end

      context 'when the relation is a references one' do
        let(:game) do
          person.build_game
        end

        it 'does not set a binding attribute' do
          expect(game[:binding]).to be_nil
        end
      end

      context 'when the relation is a belongs to' do
        context 'when the inverse is a has many' do
          let(:post) do
            Post.new
          end

          let!(:person) do
            post.build_person
          end

          it 'builds the document' do
            expect(post.person).to eq(person)
          end

          it 'sets the inverse' do
            expect(person.posts).to eq([ post ])
          end

          it 'does not save the document' do
            expect(person).not_to be_persisted
          end
        end

        context 'when the inverse is a has one' do
          let(:game) do
            Game.new
          end

          let!(:person) do
            game.build_person
          end

          it 'builds the document' do
            expect(game.person).to eq(person)
          end

          it 'sets the inverse' do
            expect(person.game).to eq(game)
          end

          it 'does not save the document' do
            expect(person).not_to be_persisted
          end
        end
      end
    end

    context 'when providing a type argument' do
      context 'when the relation is an embeds_one' do
        let(:canvas) { Canvas.new }

        context 'when the type is a subclass of the association class' do
          let(:writer) { canvas.build_writer({}, PdfWriter) }

          it 'builds an instance of the specified type' do
            expect(writer).to be_a(PdfWriter)
          end

          it 'assigns the built document to the association' do
            writer # build the association
            expect(canvas.writer).to eq(writer)
          end

          it 'does not persist the document' do
            expect(writer).not_to be_persisted
          end
        end

        context 'when no type is given' do
          let(:writer) { canvas.build_writer(speed: 3) }

          it 'builds an instance of the default association class' do
            expect(writer).to be_a(Writer)
          end

          it 'applies the given attributes' do
            expect(writer.speed).to eq(3)
          end
        end

        context 'when nil is passed as the type' do
          let(:writer) { canvas.build_writer({}, nil) }

          it 'builds an instance of the default association class' do
            expect(writer).to be_a(Writer)
          end
        end
      end
    end
  end

  describe "#create_#\{name}" do
    let(:person) do
      Person.new
    end

    context 'when providing no attributes' do
      context 'when the relation is an embeds one' do
        let(:name) do
          person.create_name
        end

        it 'does not set a binding attribute' do
          expect(name[:binding]).to be_nil
        end
      end

      context 'when the relation is a references one' do
        let(:game) do
          person.create_game
        end

        it 'does not set a binding attribute' do
          expect(game[:binding]).to be_nil
        end
      end

      context 'when the relation is a belongs to' do
        context 'when the inverse is a has many' do
          let(:post) do
            Post.new
          end

          let!(:person) do
            post.create_person
          end

          it 'builds the document' do
            expect(post.person).to eq(person)
          end

          it 'sets the inverse' do
            expect(person.posts).to eq([ post ])
          end

          it 'saves the document' do
            expect(person).to be_persisted
          end

          it 'saves the child' do
            expect(post).to be_persisted
          end
        end

        context 'when the inverse is a has one' do
          let(:game) do
            Game.new
          end

          let!(:person) do
            game.create_person
          end

          it 'builds the document' do
            expect(game.person).to eq(person)
          end

          it 'sets the inverse' do
            expect(person.game).to eq(game)
          end

          it 'saves the document' do
            expect(person).to be_persisted
          end

          it 'saves the child' do
            expect(game).to be_persisted
          end
        end
      end
    end

    context 'when providing a type argument' do
      context 'when the relation is an embeds_one' do
        let(:canvas) { Canvas.new }

        context 'when the type is a subclass of the association class' do
          let(:writer) { canvas.create_writer({}, PdfWriter) }

          it 'builds an instance of the specified type' do
            expect(writer).to be_a(PdfWriter)
          end

          it 'assigns the built document to the association' do
            writer # create the association
            expect(canvas.writer).to eq(writer)
          end
        end

        context 'when no type is given' do
          let(:writer) { canvas.create_writer(speed: 3) }

          it 'builds an instance of the default association class' do
            expect(writer).to be_a(Writer)
          end
        end
      end
    end

    context 'when the parent is persisted' do
      let(:person) do
        Person.create!
      end

      context 'when the relation is a has one' do
        let!(:game_one) do
          person.create_game(name: 'Starcraft')
        end

        context 'when a document already exists' do
          context 'when the relation belongs_to is already set' do
            let!(:game_one) do
              game = person.create_game(name: 'Starcraft')
              game.person = person
            end

            let!(:game_two) do
              person.create_game(name: 'Skyrim')
            end

            it 'replaces the existing document' do
              expect(person.game).to eq(game_two)
            end

            it 'persists the change' do
              expect(person.game(true)).to eq(game_two)
            end

            it 'removes the old document from the database' do
              expect(Game.collection.find.count).to eq(1)
            end
          end

          context 'when the relation belongs_to is not already set' do
            let!(:game_two) do
              person.create_game(name: 'Skyrim')
            end

            it 'replaces the existing document' do
              expect(person.game).to eq(game_two)
            end

            it 'persists the change' do
              expect(person.game(true)).to eq(game_two)
            end

            it 'removes the old document from the database' do
              expect(Game.collection.find.count).to eq(1)
            end
          end
        end
      end
    end
  end

  describe '#build' do
    context 'with criteria applied' do
      subject { services.build }

      let(:person) do
        Person.new
      end

      let(:services) do
        person.services.asc(:sid)
      end

      it { is_expected.to be_a(Service) }
      it { is_expected.not_to be_persisted }
    end
  end
end
