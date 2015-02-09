# Set up a root user so we can set up authentication on a database level.
MONGOID_ROOT_USER = Mongo::Auth::User.new(
  database: Mongo::Database::ADMIN,
  user: 'mongoid-user',
  password: 'password',
  roles: [
    Mongo::Auth::Roles::USER_ADMIN_ANY_DATABASE,
    Mongo::Auth::Roles::DATABASE_ADMIN_ANY_DATABASE,
    Mongo::Auth::Roles::READ_WRITE_ANY_DATABASE,
    Mongo::Auth::Roles::HOST_MANAGER
  ]
)

# Test user for the suite for versions 2.6 and higher.
MONGOID_TEST_USER = Mongo::Auth::User.new(
  database: Mongo::Database::ADMIN,
  user: 'mongoid-test-user',
  password: 'password',
  roles: [
    { role: Mongo::Auth::Roles::READ_WRITE, db: database_id },
    { role: Mongo::Auth::Roles::DATABASE_ADMIN, db: database_id },
    { role: Mongo::Auth::Roles::READ_WRITE, db: database_id_alt },
    { role: Mongo::Auth::Roles::DATABASE_ADMIN, db: database_id_alt },
    { role: Mongo::Auth::Roles::READ_WRITE, db: 'mongoid_optional' },
    { role: Mongo::Auth::Roles::DATABASE_ADMIN, db: 'mongoid_optional' }
  ]
)

# Test user for the suite for version 2.4.
MONGOID_LEGACY_TEST_USER = Mongo::Auth::User.new(
  database: database_id,
  user: 'mongoid-test-user',
  password: 'password',
  roles: [ Mongo::Auth::Roles::READ_WRITE, Mongo::Auth::Roles::DATABASE_ADMIN ]
)
