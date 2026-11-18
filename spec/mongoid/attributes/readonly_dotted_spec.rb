# frozen_string_literal: true

require 'spec_helper'

describe 'Readonly dotted attributes' do
  let(:model_class) do
    test_model do
      field :stored_settings, as: :settings, type: Hash
      field :other_settings, type: Hash
      attr_readonly :settings
    end
  end

  let(:document) do
    model_class.create!(settings: { 'is_admin' => false }, other_settings: { 'enabled' => false })
  end

  def expect_stored_value(field, value)
    expect(model_class.collection.find(_id: document.id).first[field]).to eq(value)
  end

  shared_examples 'a readonly dotted attribute' do |path, field, original_value|
    it 'ignores write_attribute' do
      document.write_attribute(path, true)
      document.save!

      expect_stored_value(field, original_value)
    end

    it 'ignores the bracket setter' do
      document[path.to_sym] = true
      document.save!

      expect_stored_value(field, original_value)
    end

    it 'raises ReadonlyAttribute from update_attribute' do
      expect do
        document.update_attribute(path, true)
      end.to raise_error(Mongoid::Errors::ReadonlyAttribute)

      expect_stored_value(field, original_value)
    end
  end

  context 'without dynamic attributes' do
    context 'with the database field name' do
      include_examples 'a readonly dotted attribute',
                       'stored_settings.is_admin', 'stored_settings', { 'is_admin' => false }
    end

    context 'with the field alias' do
      include_examples 'a readonly dotted attribute',
                       'settings.is_admin', 'stored_settings', { 'is_admin' => false }
    end

    context 'with a new key in the readonly field' do
      include_examples 'a readonly dotted attribute',
                       'settings.new_key', 'stored_settings', { 'is_admin' => false }
    end

    context 'with a deeply nested key' do
      let(:document) do
        model_class.create!(settings: { 'permissions' => { 'is_admin' => false } })
      end

      include_examples 'a readonly dotted attribute',
                       'settings.permissions.is_admin', 'stored_settings', { 'permissions' => { 'is_admin' => false } }
    end

    it 'allows the readonly field to be initialized on a new document' do
      expect_stored_value('stored_settings', 'is_admin' => false)
    end

    it 'allows dotted writes to an unprotected field' do
      document.write_attribute('other_settings.enabled', true)
      document.save!

      expect_stored_value('other_settings', 'enabled' => true)
    end

    it 'continues to protect an exact dotted readonly name' do
      model_class.attr_readonly('other_settings.enabled')
      document.write_attribute('other_settings.enabled', true)
      document.save!

      expect_stored_value('other_settings', 'enabled' => false)
    end

    it 'rejects an unknown dotted field during mass assignment' do
      expect do
        document.update('stored_settings.is_admin' => true)
      end.to raise_error(Mongoid::Errors::UnknownAttribute)

      expect_stored_value('stored_settings', 'is_admin' => false)
    end
  end

  context 'with dynamic attributes' do
    let(:model_class) do
      test_model do
        include Mongoid::Attributes::Dynamic

        field :stored_settings, as: :settings, type: Hash
        field :other_settings, type: Hash
        attr_readonly :settings
      end
    end

    context 'with the database field name' do
      include_examples 'a readonly dotted attribute',
                       'stored_settings.is_admin', 'stored_settings', { 'is_admin' => false }
    end

    context 'with the field alias' do
      include_examples 'a readonly dotted attribute',
                       'settings.is_admin', 'stored_settings', { 'is_admin' => false }
    end

    context 'with a new key in the readonly field' do
      include_examples 'a readonly dotted attribute',
                       'settings.new_key', 'stored_settings', { 'is_admin' => false }

      it 'ignores mass assignment' do
        document.update('settings.new_key' => true)

        expect_stored_value('stored_settings', 'is_admin' => false)
      end
    end

    context 'with a deeply nested key' do
      let(:document) do
        model_class.create!(settings: { 'permissions' => { 'is_admin' => false } })
      end

      include_examples 'a readonly dotted attribute',
                       'settings.permissions.is_admin', 'stored_settings', { 'permissions' => { 'is_admin' => false } }

      it 'ignores mass assignment' do
        document.update('settings.permissions.is_admin' => true)

        expect_stored_value('stored_settings', 'permissions' => { 'is_admin' => false })
      end
    end

    it 'ignores mass assignment using the database field name' do
      document.update('stored_settings.is_admin' => true)

      expect_stored_value('stored_settings', 'is_admin' => false)
    end

    it 'ignores mass assignment using the field alias' do
      document.update('settings.is_admin' => true)

      expect_stored_value('stored_settings', 'is_admin' => false)
    end

    it 'does not persist the dotted field through update_attribute' do
      begin
        document.update_attribute('settings.is_admin', true)
      rescue Mongoid::Errors::ReadonlyAttribute
        # update_attribute is expected to raise for readonly attributes.
      end

      expect_stored_value('stored_settings', 'is_admin' => false)
    end
  end

  context 'when a nested path is readonly' do
    let(:model_class) do
      test_model do
        field :stored_settings, as: :settings, type: Hash
        attr_readonly 'settings.permissions.protected'
      end
    end

    let(:document) do
      model_class.create!(settings: { 'permissions' => { 'protected' => { 'is_admin' => false } } })
    end

    include_examples 'a readonly dotted attribute',
                     'settings.permissions.protected.is_admin', 'stored_settings',
                     { 'permissions' => { 'protected' => { 'is_admin' => false } } }

    include_examples 'a readonly dotted attribute',
                     'stored_settings.permissions.protected.is_admin', 'stored_settings',
                     { 'permissions' => { 'protected' => { 'is_admin' => false } } }

    it 'allows writes to the immediate parent' do
      document.write_attribute('settings.permissions', 'protected' => { 'is_admin' => true })
      document.save!

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows the bracket setter for the top-level parent' do
      document[:settings] = { 'permissions' => { 'protected' => { 'is_admin' => true } } }
      document.save!

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows mass assignment to the top-level parent' do
      document.update(settings: { 'permissions' => { 'protected' => { 'is_admin' => true } } })

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows update_attribute on the top-level parent' do
      document.update_attribute('settings', 'permissions' => { 'protected' => { 'is_admin' => true } })

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows removing the top-level parent' do
      document.remove_attribute('settings')
      document.save!

      expect_stored_value('stored_settings', nil)
    end

    it 'allows replacing the immediate parent with a scalar' do
      document.write_attribute('settings.permissions', 'none')
      document.save!

      expect_stored_value('stored_settings', 'permissions' => 'none')
    end

    it 'allows an in-place change to the parent hash' do
      document.settings['permissions']['protected']['is_admin'] = true
      document.save!

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows replacing a parent inside the hash' do
      document.settings['permissions'] = { 'protected' => { 'is_admin' => true } }
      document.save!

      expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
    end

    it 'allows writes to a sibling with a similar name' do
      document.write_attribute('settings.permissions.protected_extra', true)
      document.save!

      expect_stored_value(
        'stored_settings',
        'permissions' => { 'protected' => { 'is_admin' => false }, 'protected_extra' => true }
      )
    end

    context 'with dynamic attributes' do
      let(:model_class) do
        test_model do
          include Mongoid::Attributes::Dynamic

          field :stored_settings, as: :settings, type: Hash
          attr_readonly 'settings.permissions.protected'
        end
      end

      include_examples 'a readonly dotted attribute',
                       'settings.permissions.protected.is_admin', 'stored_settings',
                       { 'permissions' => { 'protected' => { 'is_admin' => false } } }

      it 'ignores mass assignment to a descendant' do
        document.update('settings.permissions.protected.is_admin' => true)

        expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => false } })
      end

      it 'allows mass assignment to a parent' do
        document.update('settings.permissions' => { 'protected' => { 'is_admin' => true } })

        expect_stored_value('stored_settings', 'permissions' => { 'protected' => { 'is_admin' => true } })
      end
    end
  end

  context 'with a separate field whose name contains a dot' do
    min_server_version '5.0'

    let(:document) { model_class.create!(settings: { 'theme' => 'light' }) }

    context 'when the dotted field is readonly' do
      let(:model_class) do
        test_model do
          field :settings, type: Hash
          field :'settings.is_admin', type: String, default: 'literal field'
          attr_readonly :'settings.is_admin'
        end
      end

      it 'allows updating the separate field' do
        document.settings = { 'theme' => 'dark' }
        document.save!

        expect_stored_value('settings', 'theme' => 'dark')
        expect_stored_value('settings.is_admin', 'literal field')
      end

      it 'allows updating a nested hash with the same name as the dotted field' do
        document.write_attribute('settings.is_admin.enabled', true)
        document.save!

        expect_stored_value('settings', 'theme' => 'light', 'is_admin' => { 'enabled' => true })
        expect_stored_value('settings.is_admin', 'literal field')
      end

      it 'still treats the dotted field as readonly' do
        expect do
          document.update_attribute('settings.is_admin', 'new value')
        end.to raise_error(Mongoid::Errors::ReadonlyAttribute)
      end
    end

    context 'when the separate field is readonly' do
      let(:model_class) do
        test_model do
          field :settings, type: Hash
          field :'settings.is_admin', type: String, default: 'literal field'
          attr_readonly :settings
        end
      end

      it 'raises the invalid dotted assignment error for the dotted field' do
        expect do
          document.update_attribute('settings.is_admin', 'new value')
        end.to raise_error(Mongoid::Errors::InvalidDotDollarAssignment)
      end
    end
  end
end
