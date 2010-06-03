namespace :db do

  desc 'Drops all the collections for the database for the current Rails.env'
  task :drop => :environment do
    Mongoid.master.collections.each{|col| col.drop unless col.name == 'system.users' }
  end

  if not Rake::Task.task_defined?("db:seed")
    # if another ORM has defined db:seed, don't run it twice.
    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      seed_file = File.join(Rails.root, 'db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end
  end
  
  desc 'Create the database, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:seed' ]

  desc 'Delete data and seed'
  task :reseed => [ 'db:drop', 'db:seed' ]

  task :create => :environment do
    # noop
  end

  task :migrate => :environment do
    # noop
  end

  namespace :schema do
    task :load do
      # noop
    end
  end

  ########
  # TODO: lots more useful db tasks can be added here. stuff like copyDatabase, etc
  ########
end
