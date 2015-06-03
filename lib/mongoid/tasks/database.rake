namespace :db do
  namespace :mongoid do
    task :load_models do
    end

    desc "Create the indexes defined on your mongoid models"
    task :create_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.create_indexes
    end

    desc "Remove indexes that exist in the database but aren't specified on the models"
    task :remove_undefined_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.remove_undefined_indexes
    end

    desc "Remove the indexes defined on your mongoid models without questions!"
    task :remove_indexes => [:environment, :load_models] do
      ::Mongoid::Tasks::Database.remove_indexes
    end

    desc "Drops the default client database"
    task :drop => :environment do
      ::Mongoid::Clients.default.database.drop
    end

    desc "Drop all collections except the system collections"
    task :purge => :environment do
      ::Mongoid.purge!
    end
  end
end
