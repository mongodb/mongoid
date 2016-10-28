load 'mongoid/tasks/database.rake'

namespace :db do

  unless Rake::Task.task_defined?("db:drop")
    desc "Drops all the collections for the database for the current Rails.env"
    task :drop => "mongoid:drop"
  end

  unless Rake::Task.task_defined?("db:purge")
    desc "Drop all collections except the system collections"
    task :purge => "mongoid:purge"
  end

  unless Rake::Task.task_defined?("db:seed")
    # if another ORM has defined db:seed, don"t run it twice.
    desc "Load the seed data from db/seeds.rb"
    task :seed => :environment do
      seed_file = File.join(Rails.root, "db", "seeds.rb")
      load(seed_file) if File.exist?(seed_file)
    end
  end

  unless Rake::Task.task_defined?("db:setup")
    desc "Create the database, and initialize with the seed data"
    task :setup => [ "db:create", "mongoid:create_indexes", "db:seed" ]
  end

  unless Rake::Task.task_defined?("db:reset")
    desc "Delete data and loads the seeds"
    task :reset => [ "db:drop", "db:seed" ]
  end

  unless Rake::Task.task_defined?("db:create")
    task :create => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:migrate")
    task :migrate => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:schema:load")
    namespace :schema do
      task :load do
        # noop
      end
    end
  end

  unless Rake::Task.task_defined?("db:test:prepare")
    namespace :test do
      task :prepare => "mongoid:create_indexes"
    end
  end

  unless Rake::Task.task_defined?("db:create_indexes")
    task :create_indexes => "mongoid:create_indexes"
  end

  unless Rake::Task.task_defined?("db:remove_indexes")
    task :remove_indexes => "mongoid:remove_indexes"
  end

  namespace :mongoid do
    task :load_models do
      ::Rails.application.eager_load! if defined?(::Rails)
    end
  end
end
