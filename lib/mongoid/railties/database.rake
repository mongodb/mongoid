namespace :db do

  if not Rake::Task.task_defined?("db:drop")
    desc 'Drops all the collections for the database for the current Rails.env'
    task :drop => :environment do
      Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
    end
  end

  if not Rake::Task.task_defined?("db:seed")
    # if another ORM has defined db:seed, don't run it twice.
    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      seed_file = File.join(Rails.root, 'db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end
  end

  if not Rake::Task.task_defined?("db:setup")
    desc 'Create the database, and initialize with the seed data'
    task :setup => [ 'db:create', 'db:create_indexes', 'db:seed' ]
  end

  if not Rake::Task.task_defined?("db:reseed")
    desc 'Delete data and seed'
    task :reseed => [ 'db:drop', 'db:seed' ]
  end

  if not Rake::Task.task_defined?("db:create")
    task :create => :environment do
      # noop
    end
  end

  if not Rake::Task.task_defined?("db:migrate")
    task :migrate => :environment do
      # noop
    end
  end

  if not Rake::Task.task_defined?("db:schema:load")
    namespace :schema do
      task :load do
        # noop
      end
    end
  end

  if not Rake::Task.task_defined?("db:test:prepare")
    namespace :test do
      task :prepare do
        # noop
      end
    end
  end

  if not Rake::Task.task_defined?("db:create_indexes")
    desc 'Create the indexes defined on your mongoid models'
    task :create_indexes => :environment do
      documents = []
      Dir.glob("app/models/**/*.rb").sort.each do |file|
        model = file.match(/\/(\w+).rb$/)[1]
        klass = model.classify.constantize
        begin
          documents << klass unless klass.embedded
        rescue => e
          # Just for non-mongoid objects that dont have the embedded
          # attribute at the class level.
        end
      end
      ::Rails::Mongoid.index_children(documents)
    end
  end

  namespace :mongoid do

    desc "Convert string objectids in mongo database to ObjectID type"
    task :convert_to_objectids => :environment do

      require 'ruby-debug';debugger
      puts Mongoid.descendents



    end

  end


  ########
  # TODO: lots more useful db tasks can be added here. stuff like copyDatabase, etc
  ########
end
