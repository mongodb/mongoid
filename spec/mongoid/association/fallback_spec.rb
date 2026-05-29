require 'spec_helper'

describe 'associations with the :fallback option' do
  before(:all) do
    class Anonymous
      def attribution
        'Composer unknown'
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :Anonymous)
  end

  context 'belongs_to' do
    before(:all) do
      class Composer
        include Mongoid::Document

        field :name

        def attribution
          "Composed by #{name}"
        end
      end

      class Symphony
        include Mongoid::Document

        belongs_to :composer, fallback: -> { Anonymous.new }
      end
    end

    after(:all) do
      Object.send(:remove_const, :Symphony)
      Object.send(:remove_const, :Composer)
    end

    it 'returns a fresh null object instance on every access when the association is nil' do
      symphony = Symphony.create!

      expect(symphony.composer.attribution).to eq('Composer unknown')
      expect(symphony.composer).not_to equal(symphony.composer)
    end

    it 'returns the real associated document when the FK is set' do
      symphony = Symphony.create!(composer: Composer.create!(name: 'Mahler'))

      expect(Symphony.find(symphony.id).composer.attribution).to eq('Composed by Mahler')
    end

    it 'treats a direct null object assignment as nil' do
      symphony = Symphony.create!

      symphony.composer = Anonymous.new
      symphony.save!

      expect(Symphony.find(symphony.id).composer_id).to be_nil
    end

    it 'treats a null object passed via the constructor as nil' do
      symphony = Symphony.create!(composer: Anonymous.new)

      expect(Symphony.find(symphony.id).composer_id).to be_nil
    end
  end

  context 'has_one' do
    before(:all) do
      class Composer
        include Mongoid::Document

        field :name

        belongs_to :symphony

        def attribution
          "Composed by #{name}"
        end
      end

      class Symphony
        include Mongoid::Document

        has_one :composer, fallback: -> { Anonymous.new }
      end
    end

    after(:all) do
      Object.send(:remove_const, :Symphony)
      Object.send(:remove_const, :Composer)
    end

    it 'returns a fresh null object instance on every access when the association is nil' do
      symphony = Symphony.create!

      expect(symphony.composer.attribution).to eq('Composer unknown')
      expect(symphony.composer).not_to equal(symphony.composer)
    end

    it 'returns the real associated document when one exists' do
      symphony = Symphony.create!
      Composer.create!(symphony: symphony, name: 'Mahler')

      expect(Symphony.find(symphony.id).composer.attribution).to eq('Composed by Mahler')
    end

    it 'treats a direct null object assignment as nil' do
      symphony = Symphony.create!

      symphony.composer = Anonymous.new
      symphony.save!

      expect(Composer.where(symphony_id: symphony.id).first).to be_nil
    end

    it 'treats a null object passed via the constructor as nil' do
      symphony = Symphony.create!(composer: Anonymous.new)

      expect(Composer.where(symphony_id: symphony.id).first).to be_nil
    end
  end

  context 'embeds_one' do
    before(:all) do
      class Composer
        include Mongoid::Document

        field :name

        embedded_in :symphony

        def attribution
          "Composed by #{name}"
        end
      end

      class Symphony
        include Mongoid::Document

        embeds_one :composer, fallback: -> { Anonymous.new }
      end
    end

    after(:all) do
      Object.send(:remove_const, :Symphony)
      Object.send(:remove_const, :Composer)
    end

    it 'returns a fresh null object instance on every access when the association is nil' do
      symphony = Symphony.create!

      expect(symphony.composer.attribution).to eq('Composer unknown')
      expect(symphony.composer).not_to equal(symphony.composer)
    end

    it 'returns the real embedded document when one exists' do
      symphony = Symphony.create!(composer: Composer.new(name: 'Mahler'))

      expect(Symphony.find(symphony.id).composer.attribution).to eq('Composed by Mahler')
    end

    it 'treats a direct null object assignment as nil' do
      symphony = Symphony.create!

      symphony.composer = Anonymous.new
      symphony.save!

      expect(Symphony.collection.find(_id: symphony.id).first['composer']).to be_nil
    end

    it 'treats a null object passed via the constructor as nil' do
      symphony = Symphony.create!(composer: Anonymous.new)

      expect(Symphony.collection.find(_id: symphony.id).first['composer']).to be_nil
    end
  end

  context 'with a dependent strategy and no real associated document' do
    before(:all) do
      class Composer
        include Mongoid::Document
      end
    end

    after(:all) do
      Object.send(:remove_const, :Composer)
    end

    context 'when the strategy is :destroy' do
      before(:all) do
        class Symphony
          include Mongoid::Document

          has_one :composer, dependent: :destroy, fallback: -> { Anonymous.new }
        end
      end

      after(:all) do
        Object.send(:remove_const, :Symphony)
      end

      it 'does not apply the strategy to the fallback when destroying the owner' do
        symphony = Symphony.create!

        expect { symphony.destroy }.not_to raise_error
      end
    end

    context 'when the strategy is :nullify' do
      before(:all) do
        class Symphony
          include Mongoid::Document

          has_one :composer, dependent: :nullify, fallback: -> { Anonymous.new }
        end
      end

      after(:all) do
        Object.send(:remove_const, :Symphony)
      end

      it 'does not apply the strategy to the fallback when destroying the owner' do
        symphony = Symphony.create!

        expect { symphony.destroy }.not_to raise_error
      end
    end

    context 'when the strategy is :delete_all' do
      before(:all) do
        class Symphony
          include Mongoid::Document

          has_one :composer, dependent: :delete_all, fallback: -> { Anonymous.new }
        end
      end

      after(:all) do
        Object.send(:remove_const, :Symphony)
      end

      it 'does not apply the strategy to the fallback when destroying the owner' do
        symphony = Symphony.create!

        expect { symphony.destroy }.not_to raise_error
      end
    end

    context 'when the strategy is :restrict_with_exception' do
      before(:all) do
        class Symphony
          include Mongoid::Document

          has_one :composer, dependent: :restrict_with_exception, fallback: -> { Anonymous.new }
        end
      end

      after(:all) do
        Object.send(:remove_const, :Symphony)
      end

      it 'does not apply the strategy to the fallback when destroying the owner' do
        symphony = Symphony.create!

        expect { symphony.destroy }.not_to raise_error
      end
    end

    context 'when the strategy is :restrict_with_error' do
      before(:all) do
        class Symphony
          include Mongoid::Document

          has_one :composer, dependent: :restrict_with_error, fallback: -> { Anonymous.new }
        end
      end

      after(:all) do
        Object.send(:remove_const, :Symphony)
      end

      it 'does not block destroying the owner because of the fallback' do
        symphony = Symphony.create!

        expect(symphony.destroy).to be_truthy
      end
    end
  end

  context 'on a polymorphic belongs_to' do
    before(:all) do
      class Composer
        include Mongoid::Document
      end

      class Symphony
        include Mongoid::Document

        belongs_to :author, polymorphic: true, fallback: -> { Anonymous.new }
      end
    end

    after(:all) do
      Object.send(:remove_const, :Symphony)
      Object.send(:remove_const, :Composer)
    end

    it 'does not raise when assigning a real document' do
      symphony = Symphony.new

      expect { symphony.author = Composer.new }.not_to raise_error
    end

    it 'treats a null object assignment as nil' do
      symphony = Symphony.new

      expect { symphony.author = Anonymous.new }.not_to raise_error
      expect(symphony.author_id).to be_nil
    end
  end

  context 'with nested attributes' do
    before(:all) do
      class Composer
        include Mongoid::Document

        field :name

        embedded_in :symphony
      end

      class Symphony
        include Mongoid::Document

        embeds_one :composer, fallback: -> { Anonymous.new }
        accepts_nested_attributes_for :composer
      end
    end

    after(:all) do
      Object.send(:remove_const, :Symphony)
      Object.send(:remove_const, :Composer)
    end

    it 'builds the nested document instead of operating on the fallback' do
      symphony = Symphony.new

      expect { symphony.composer_attributes = { name: 'Mahler' } }.not_to raise_error
      expect(symphony.composer.name).to eq('Mahler')
    end
  end

  context 'validation of the :fallback option' do
    it 'rejects a declaration that combines :fallback with :autobuild' do
      expect do
        Class.new do
          include Mongoid::Document

          belongs_to :composer, fallback: -> { Object.new }, autobuild: true
        end
      end.to raise_error(Mongoid::Errors::InvalidRelationOption)
    end

    it 'rejects a non-callable :fallback value' do
      expect do
        Class.new do
          include Mongoid::Document

          belongs_to :composer, fallback: Object.new
        end
      end.to raise_error(ArgumentError, /must be a Proc or lambda/)
    end
  end
end
