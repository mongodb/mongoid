# frozen_string_literal: true
# rubocop:todo all

namespace :db do
  namespace :mongoid do
    task :load_models do
      ::Mongoid.load_models
    end

    desc "Create collections for Mongoid models"
    task :create_collections => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.create_collections
    end

    desc "Create indexes specified in Mongoid models"
    task :create_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.create_indexes
    end

    desc "Create search indexes specified in Mongoid models"
    task :create_search_indexes => [:environment, :load_models] do
      wait = Mongoid::Utils.truthy_string?(ENV['WAIT_FOR_SEARCH_INDEXES'] || '1')
      ::Mongoid::Tasks::Database.create_search_indexes(wait: wait)
    end

    desc "Remove indexes that exist in the database but are not specified in Mongoid models"
    task :remove_undefined_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.remove_undefined_indexes
    end

    desc "Remove indexes specified in Mongoid models"
    task :remove_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.remove_indexes
    end

    desc "Remove search indexes specified in Mongoid models"
    task :remove_search_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.remove_search_indexes
    end

    desc "Shard collections with shard keys specified in Mongoid models"
    task :shard_collections => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.shard_collections
    end

    desc "Drop the database of the default Mongoid client"
    task :drop => :environment do
      ::Mongoid::Clients.default.database.drop
    end

    desc "Drop all non-system collections"
    task :purge => :environment do
      ::Mongoid.purge!
    end

    namespace :create_collections do
      desc "Drop and create collections for Mongoid models"
      task :force => [:environment, :load_models] do
        ::Mongoid::Tasks::Database.create_collections(force: true)
      end
    end
  end
end
