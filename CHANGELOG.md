# Overview

For instructions on upgrading to newer versions, visit
[mongoid.org](http://mongoid.org/en/mongoid/docs/upgrading.html).

### As of version 5.0.2, please refer to the github releases for change logs.

## 5.0.1

### Resolved Issues

* [MONGOID-3020](https://jira.mongodb.org/browse/MONGOID-3020) Test added to show it's no longer an issue.
* [MONGOID-3025](https://jira.mongodb.org/browse/MONGOID-3025) Test added to show it's no longer an issue.
* [MONGOID-3061](https://jira.mongodb.org/browse/MONGOID-3061) No longer an issue.
* [MONGOID-3073](https://jira.mongodb.org/browse/MONGOID-3073) Test added to show it's no longer an issue.
* [MONGOID-3085](https://jira.mongodb.org/browse/MONGOID-3085) Test added to show it's no longer an issue.
* [MONGOID-3101](https://jira.mongodb.org/browse/MONGOID-3101) No longer an issue.
* [MONGOID-3160](https://jira.mongodb.org/browse/MONGOID-3160) No longer an issue.
* [MONGOID-3176](https://jira.mongodb.org/browse/MONGOID-3176) No longer an issue.
* [MONGOID-3214](https://jira.mongodb.org/browse/MONGOID-3214) Test added to show it's no longer an issue.
* [MONGOID-3296](https://jira.mongodb.org/browse/MONGOID-3296) Add update callback for counter_cache.
* [MONGOID-3326](https://jira.mongodb.org/browse/MONGOID-3326) Test added to show it's no longer an issue.
* [MONGOID-3361](https://jira.mongodb.org/browse/MONGOID-3361) No longer an issue.
* [MONGOID-3365](https://jira.mongodb.org/browse/MONGOID-3365) Test added to show it's no longer an issue.
* [MONGOID-3402](https://jira.mongodb.org/browse/MONGOID-3402) Apply persistence options to parent.
* [MONGOID-3524](https://jira.mongodb.org/browse/MONGOID-3524) No longer an issue.
* [MONGOID-3529](https://jira.mongodb.org/browse/MONGOID-3529) Test exists already showing it's not an issue.
* [MONGOID-3543](https://jira.mongodb.org/browse/MONGOID-3543) Test exists already showing it's not an issue.
* [MONGOID-3611](https://jira.mongodb.org/browse/MONGOID-3611) Test added to show it's no longer an issue.
* [MONGOID-3650](https://jira.mongodb.org/browse/MONGOID-3650) No longer an issue.
* [MONGOID-3826](https://jira.mongodb.org/browse/MONGOID-3826), [MONGOID-4109](https://jira.mongodb.org/browse/MONGOID-4109) Fix Timelessness leaks.
* [MONGOID-3946](https://jira.mongodb.org/browse/MONGOID-3946) Test added to show it's no longer an issue.
* [MONGOID-3969](https://jira.mongodb.org/browse/MONGOID-3969) Test added to show it's no longer an issue.
* [MONGOID-3971](https://jira.mongodb.org/browse/MONGOID-3971) Not an issue.
* [MONGOID-3979](https://jira.mongodb.org/browse/MONGOID-3979) Not an issue, tests exist already.
* [MONGOID-3985](https://jira.mongodb.org/browse/MONGOID-3985) Not an issue.
* [MONGOID-4078](https://jira.mongodb.org/browse/MONGOID-4078) Behavior is intended.
* [MONGOID-4079](https://jira.mongodb.org/browse/MONGOID-4079) Not an issue.
* [MONGOID-4088](https://jira.mongodb.org/browse/MONGOID-4088) Account for sub-document dot notation with #pluck results.
* [MONGOID-4098](https://jira.mongodb.org/browse/MONGOID-4098) Fixed by a change to the Ruby driver. See RUBY-1029.
* [MONGOID-4101](https://jira.mongodb.org/browse/MONGOID-4101) Not an issue.
* [MONGOID-4106](https://jira.mongodb.org/browse/MONGOID-4106) Not an issue.
* [MONGOID-4110](https://jira.mongodb.org/browse/MONGOID-4110) Not an issue.
* [MONGOID-4119](https://jira.mongodb.org/browse/MONGOID-4119) Ensure that criteria selector becomes pipeline operator value.
* [MONGOID-4121](https://jira.mongodb.org/browse/MONGOID-4121) Not an issue.
* [MONGOID-4123](https://jira.mongodb.org/browse/MONGOID-4123) Fixed as a result of MONGOID-4159.
* [MONGOID-4125](https://jira.mongodb.org/browse/MONGOID-4125) Make sure none scopes referenced in procs are applied.
* [MONGOID-4132](https://jira.mongodb.org/browse/MONGOID-4132) Not an issue.
* [MONGOID-4157](https://jira.mongodb.org/browse/MONGOID-4157) Fixed by version 2.1.2 of the Ruby driver.
* [MONGOID-4162](https://jira.mongodb.org/browse/MONGOID-4162) Adapt index option mappings to new driver. (@Nielsomat)
* [MONGOID-3737](https://jira.mongodb.org/browse/MONGOID-3737) Test added to show it's no longer an issue.
* [MONGOID-3621](https://jira.mongodb.org/browse/MONGOID-3621) Not an issue.
* [MONGOID-3551](https://jira.mongodb.org/browse/MONGOID-3551) Not an issue.
* [MONGOID-3696](https://jira.mongodb.org/browse/MONGOID-3696) Test added to show it's no longer an issue.
* [MONGOID-3858](https://jira.mongodb.org/browse/MONGOID-3858) Test added to show it's no longer an issue.
* [MONGOID-3672](https://jira.mongodb.org/browse/MONGOID-3672) Not an issue.
* [MONGOID-4172](https://jira.mongodb.org/browse/MONGOID-4172) Use positional operator only on 1 level deep nesting.
* Added public cert to repo and sign gem if private key is present

## 5.0.0

### Major Changes (Backwards Incompatible)

* Mongoid now uses the official Mongo Ruby Driver 2.x instead of Moped.

* Most driver specific configuration options have changed, please see [here](http://docs.mongodb.org/ecosystem/tutorial/ruby-driver-tutorial/#ruby-options) for the new options.

* All references to `session` are now replaced with `client`. This includes the mongoid.yml configuration, `store_in` options, and all exceptions and modules with `Session` in the name.

* `find_and_modify` has been removed and replaced with 3 options: `find_one_and_update`, `find_one_and_delete` and `find_one_and_replace`.

* `text_search` has been removed as it is now a `$text` option in a query from 2.6 on.

* Mongoid no longer supports MongoDB 2.2 - support is now for only 2.4 and higher.

* \#3768 `first` and `last` no longer add an `_id` sort when no sorting options have been provided. In order to guarantee that a document is the first or last, it needs to now contain an explicit sort.

* `Document#deleted?` alias has been removed, please continue to use `Document#destroyed?`.

### New Features

* \#4016 Allow private and protected setters on fields for atomic operations. (Rob Smith)

* \#3985 Return nil when using `{upsert: true}` in `find_and_modify` (Adrien Siami)

* \#3963 Allow extended JSON object ids to be passed to `find`.

* \#3846 Allow #pluck when none is used in criteria. (Braulio Martinez)

### Resolved Issues

* \#4091 Use sublcass context when calling a scope defined in a superclass. (Edgars Beigarts)

* \#4075 Made remove index logging specific to each index that was actually getting removed.

* \#4071 Fixed loading of enumerable relation to check the added documents when iterating.

* \#4077 Many relations now include Enumerable.

* \#4052 Fixed uniqueness validation on localized fields with no value.

* \#4033 Removed all uses of the $ positional operator in atomic updates.

* \#4030 Dup/clone exceptions auto-include dynamic attributes.

* \#4005 Fixed inclusion of mongoid with Rails components that don't have the Rails environment.

* \#3993 Fixes issue where `dup`/`clone` fails for embedded documents that use store_as without using Mongoid::Atributes::Dynamic

* \#3991 Fixed emebdded documents not flagging as changed after calling #changed? and modifying the
child elements.

* \#3874 Adding snapshot option to context.

* \#3868 Loading models in rake tasks now expands the rails path.

* \#3764 Fixed case statement check for enumerable targets.

* \#3740 Fixes `Missing attribute: '_id'` error when using methods only or without (dx7)

* \#3631 Fixes issue where `before_save` callback can get called twice after a child create

* \#3599 Fixed application of default scopes from superclass in subclasses.

* \#3104 Fixed enumerable targets to check first/last in proper order.

## 4.0.2

### New Features

* \#3931 Add #find_or_create_by! method to many associations. (Tom Beynon)

* \#3731 Add find_by! method. (Guillermo Iguaran)

### Resolved Issues

* \#3722 Use the right database name when combining #store_in and #with. (Arthur Neves)

* \#3934 Dont apply sort when doing a find_by. (Arthur Neves)

* \#3935 fix multiple fields sorting on contextual memory. (chamnap)

* \#3904 BSON::Document#symbolize_keys should return keys as symbols. (Arthur Neves)

* \#3948 Fix remove_undefined_indexes on rails 4.2, to symbolize right the Document keys. (Adam Wróbel)

* \#3626 Document#to_key, needs to return a ObjectId as String so we can query back using that id. (Arthur Neves)

* \#3888 raise UnknownAttributeError when 'set' is called on non existing field and Mongoid::Attributes::Dynamic is not included in model. (Shweta Kale)

* \#3889 'set' will allow to set value of non existing field when Mongoid::Attributes::Dynamic is included in model. (Shweta Kale)

* \#3812 Fixed validation context when saving (Yaroslav Zemlyanuhin)

## 4.0.1

### Resolved Issues

* \#3911 Fix relations named "parent". (nkriege)

* \#3792/\#3881 Fix many internal calls to #_id instead of #id to avoid issues
  when overloading #id (Gauthier Delacroix)

* \#3847 Fix 'QueryCache#get_more' result, when collection has more documents than first query batch. (Angelica Korsun)

* \#3684 Dont raise MissingAttributeError, when using a only() scope. (Arthur Neves)

* \#3703 pluck method should not compact the values. (Arthur Neves)

* \#3773 Use nanoseconds for cache_key timestamp instead of plain seconds. (Máximo Mussini)

## 4.0.0

### Major Changes (Backwards Incompatible)

* \#3320 Remove Rails dependencies on database rake tasks. (Arthur Neves)

    All db:* rake tasks should work as before when using Rails.
    When not in a Rails, just load the database tasks using:

        load 'mongoid/tasks/database.rake'

* Mongoid 4 now only supports MongoDB 2.4.0 and higher.

* `Document#metadata` has been renamed to `Document#relation_metadata` to
  avoid common conflicts. Relation proxies also have this renamed to the
  same as well.

* Scopes and default scopes must now all be defined within lambdas or procs.

* `skip_version_check` config option was removed.

* IdentityMap removed. (Arthur Neves)

* Eager load rework. Eager load now doesnt need the identity map to load
  related documents. A set of preloaders can eager load the associations
  passed to .includes method. (Arthur Neves)

* Mongoid now supports the new read preferences that the core drivers
  provide. These include:

    - `:primary`: Will always read from a primary node. (default)
    - `:primary_preferred`: Attempt a primary first, then secondary if none available.
    - `:secondary`: Will always read from a secondary node.
    - `:secondary_preferred`: Attempt a secondary first, then primary if none available.
    - `:nearest`: Attempt to read from the node with the lowest latency.

    Sample syntax:

        Person.with(read: :secondary).first

    The `:consistency` option is no longer valid, use the `:read` option now.

* Mongoid now defaults all writes to propagate (formerly "safe mode") and now
  has different propagate semantics:

    - `{ w: -1 }`: Don't verify writes and raise no network errors.
    - `{ w: 0 }`: Don't verify writes and raise network errors.
    - `{ w: 1 }`: Verify writes on the primary node. (default)
    - `{ w: n }`: Verify writes on n number of nodes.
    - `{ w: "majority" }`: Verify writes on a majority of nodes.

    Sample syntax:

        Person.with(write: {w: :majority}).create!(name: "John")

    The `:safe` option is no longer valid use the `:write` option now.

* \#3230 Array and Hash fields now validate that the correct types are
  getting set, instead of allowing any value. (Rodrigo Saito)

* \#3043/\#2949 Rework on the internals of persistence options. (Arthur Neves)

* Mongoid now requires Active Model 4 or higher.

* `Document#set` now accepts multiple attributes in the form of a hash,
  instead of the previous `(field, value)` args. Field aliases and typecasting
  are also now supported in this operation.

        document.set(name: "Photek", likes: 10000)

* `Document#rename` now accepts multiple attributes in the form of a hash,
  instead of the previous `(field, value)` args. Field aliases are supported.

        document.rename(first_name: "fn", last_name: "ln")

* `Document#inc` now accepts multiple attributes in the form of a hash, instead
  of previously only being able to increment one value at a time. Aliases and
  serialization is supported.

        document.inc(score: 10, place: -1, lives: -10)

* `Document#pop` now accepts multiple attributes in the form of a hash, instead
  of previously only being able to pop one value at a time. Aliases and
  serialization is supported.

        document.pop(names: 1, aliases: -1)

* `Document#bit` now accepts multiple attributes in the form of a hash, instead
  of previously only being able to apply one set of operations at a time.
  Aliases and serialization are supported.

        document.bit(age: { and: 13 }, score: { or: 13 })

* `Document#pull` now accepts multiple attributes in the form of a hash, instead
  of previously only being able to pull one value at a time. Aliases and
  serialization is supported.

        document.pull(names: "James", aliases: "007")

* `Document#pull_all` now accepts multiple attributes in the form of a hash,
  instead of previously only being able to pull one value at a time. Aliases and
  serialization is supported.

        document.pull_all(names: ["James", "Bond"], aliases: ["007"])

* `Document#push_all` has been removed since it was deprecated in MongoDB 2.4.
  Use `Document.push` instead.

* `Document#push` now accepts multiple attributes in the form of a hash, and
  can handle the pushing of single values or multiple values to the field via
  $push with $each. Aliases and serialization is supported.

        document.push(names: "James", aliases: [ "007", "Jim" ])

* `Document#add_to_set` now accepts multiple attributes in the form of a hash,
  and now aliases and serialization are supported.

        document.add_to_set(names: "James", aliases: "007")

* Criteria atomic operations API is now changed to match the changes in the
  single document atomic API, for example:

        Band.where(name: "Depeche Mode").inc(likes: 10, followers: 20)

* \#3399 #create and #create! on relations can now take an array of attributes as
  the first parameter to create multiple documents at once.

        person.addresses.create([{ street: "Bond" }, { street: "Upper" }])
        person.addresses.create!([{ street: "Bond" }, { street: "Upper" }])

* \#3141 `rake db:test:prepare` now sets up all defined indexes if Mongoid is the
  only ODM/ORM in the environment.

* \#3138 `update_attributes` can now be accessed simply by calling `update`.

* \#3083 A new rake task: `rake db:mongoid:remove_undefined_indexes` has been added to
  remove indexes from the database that are not explicitly defined in the models.
  (Aidan Feldman)

* \#3029 The `relation_field` field that is added for a single use case with polymorphic
  relations has been removed. So where the following would work before:

        class Eye
          include Mongoid::Document
          belongs_to :eyeable, polymorphic: true
        end

        class Face
          include Mongoid::Document
          has_one :left_eye, class_name: "Eye", as: :eyeable
          has_one :right_eye, class_name: "Eye", as: :eyeable
        end

      This would now need to be modeled as (with the appropriate migration):

        class Eye
          include Mongoid::Document
          belongs_to :left_socket, class_name: "Face", inverse_of: :left_eye
          belongs_to :right_socket, class_name: "Face", inverse_of: :right_eye
        end

        class Face
          include Mongoid::Document
          has_one :left_eye, class_name: "Eye", inverse_of: :left_socket
          has_one :right_eye, class_name: "Eye", inverse_of: :right_socket
        end

* \#3075 `update_attribute` now properly calls the setter method instead of
  using `write_attribute`.

* \#3060 Allow atomically blocks to allow multiple calls of the same type.
  (Brian Norton)

* \#3037 Model indexes are no longer stored in an `index_options` hash on the
  model class. Instead, an array named `index_specifications` now exists on the
  class which contains a list of `Indexable::Specification` objects. This is so
  we could properly handle the case of indexes with the same keys but different
  order.

* \#2956 Caching on queries now only happens when `cache` is specifically
  called. (Arthur Neves)

* \#2659 `Mongoid::Railtie` now properly uses only one initializer and
  the name has changed to `mongoid.load-config`.

* \#2656 `rake db:reseed` is now `rake db:reset` (Arthur Neves)

* \#2648 `Boolean` becomes `Mongoid::Boolean` to avoid polluting the global
  namespace with a commonly used class by other libraries.

* \#2603 Return values from setters are now always the set value, regardless
  of calling the setter or using send.

* \#2597 `Mongoid::Observer` was removed in line with Rails 4.

* \#2563 The `allow_dynamic_fields` configuration option has been removed as
  dynamic fields are now allowed on a per-model level. In order to allow a
  model to use dynamic fields, simply include the module in each.
  (Josh Martin)

        class Band
          include Mongoid::Document
          include Mongoid::Attributes::Dynamic
        end

* \#2497 Calling `to_json` no longer tampers with the return value from the
  driver, and proper returns `{ "$oid" : object_id.to_s }` instead of just
  the string representation previously.

* \#2433 `Mongoid::Paranoia` has been removed.

* \#2432 `Mongoid::Versioning` has been removed.

* \#2218 Creating or instantiating documents that have default scopes will now
  apply the default scope to the document, if the scope is not complex.

* \#2200 Mass assignment security now mirrors Rails 4's behavior.
  `without_protection` option was also removed.
  `attr_accessible` class method was removed.
  Mongoid and Strong parameters should work fine for mass assignment protection.

* `delete_all` and `destroy_all` no longer take a `:conditions` hash but
  just the raw attributes.

* \#1908 Documents now loaded from criteria using `#only` or `#without` will now
  raise an error when attempting to save, update, or delete these records.
  Additionally fields excluded from the fields retrieved from the database will
  also raise an exception when trying to access them.

* \#1344 Atomic updates can now be executed in an `atomically` block, which will
  delay any atomic updates on the document the block was called on until the
  block is complete.

    Update calls can be executed as normal in the block:

        document.atomically do
          document.inc(likes: 10)
          document.bit(members: { and: 10 })
          document.set(name: "Photek")
        end

    The document is also yielded to the block:

        document.atomically do |doc|
          doc.inc(likes: 10)
          doc.bit(members: { and: 10 })
          doc.set(name: "Photek")
        end

    The atomic commands are have a fluid interface:

        document.atomically do |doc|
          doc.inc(likes: 10).bit(members: { and: 10 }).set(name: "Photek")
        end

    If the fluid interface is leveraged without the `atomically` block, the
    operations will persist in individual calls. For example, the following
    would hit the database 3 times without the block provided:

        doc.inc(likes: 10).bit(members: { and: 10 }).set(name: "Photek")

    The block is only good for 1 document at a time, so embedded and root
    document updates cannot be mixed at this time.

### New Features

* Mongoid now uses ActiveSupport::LogSubscriber to subscribe logs, and
  ActiveSupport::Notifications to send operation logs. (Arthur Neves)
  Example of log subscription:

    ActiveSupport::Notifications.subscribe('query.moped') do |event|
      ..
    end

* Field types can now use symbols as well as class names. See:
  https://github.com/mongoid/mongoid/blob/master/lib/mongoid/fields.rb#L16
  for the available mappings.

* \#3580 Fields can now be reset to their default values, with the methods:

    document.reset_name_to_default!

* \#3513 Documents now have a `#destroy!` method that will raise a
  `Mongoid::Errors::DocumentNotDestroyed` error if a destroy callback returns
  a false value.

* \#3496 Added class level and criteria level `find_or_create_by!`.

* \#3479 Map/reduce now respects criteria no timeout options if output is not
  inline.

* \#3478 Criteria objects now have a #none method that will cause the criteria to
  never hit the database and always have zero documents.

    Band.none
    Band.none.where(name: "Tool") # Always has zero documents.

* \#3410 Mongoid now has a query cache that can be used as a middleware in
  Rack applications. (Arthur Neves)

    For Rails:

      config.middleware.use(Mongoid::QueryCache::Middleware)

* \#3319 Counters can now be reset from a document instance:

    document.reset_counters(:relation)

* \#3310 embedded_in relations now accept a `touch` option to update parents.

* \#3302 Aliasing using `alias_attribute` now properly handles aliases in criteria.

* \#3155 Range field will persist the exclude_end when provided.
  (Daniel Libanori)

* \#3146 Adding :overwrite field option, when it`s true, it wont check duplicates.
 (Daniel Libanori)

* \#3002 Reloading the Rails console will also now clear Mongoid's identity map.

* \#2938 A configuration option `duplicate_fields_exception` has been added that
  when set to `true` will raise an exception when defining a field that will
  override an existing method. (Arthur Neves)

* \#2924 MongoDB 2.4 beta text search now has a DSL provided by Mongoid. Like
  other queries, text searches are lazy evaluated, and available off the class
  or criteria level.

    Note that any 3rd party gem that provides a `text_search` method will now no
    longer work with Mongoid, and will need to change its syntax. Examples:

        Band.text_search("mode").project(name: 1).each do |doc|
          # ...
        end

        Band.limit(10).text_search("phase").language("latin")
        Band.where(:likes.gt => 1000).text_search("lucy")

* \#2855 Multiple extensions can now be supplied to relations. (Daniel Libanori)

### Resolved Issues

* \#3676 Make pluck work with embedded associations
  (Arthur Neves)

* \#2898 Dirty attribute methods now properly handle field aliases.
  (Niels Ganser)

* \#3620 Add ActiveModel module instance methods to prohibited_methods list.
  (Arthur Neves)

* \#3610 Don't allow atomic operations on read-only attributes
  (Frederico Araujo)

* \#3619 Don't validate documents that are flagged for destruction.
  (Christopher J. Bottaro)

* \#3617 Don't skip index creation on cyclic documents. (shaiker)

* \#3568 Fixed missing attributes error on present localized fields.

* \#3514 Fixed query cache to work on first/last calls.

* \#3383/\#3495 Fix has_and_belongs_to_many eager load. (Arthur Neves)

* \#3492 $rename operations should not mongoize values. (Vladislav Melanitskiy)

* \#3490 Allow localized fields to work with boolean `false` values.

* \#3487 Map Boolean to Mongoid::Boolean in field definitions. (Arthur Neves)

* \#3449 Touch needs to work for create and update. (Greggory Rothmeier)

* \#3347 Creating documents off of scopes for embedded relations now properly
  sets the parent document on the created children.

* \#3432 Fixed mongoization of DateTime losing precision.

* \#3397 Fixed $ne matcher for embedded documents to match server behaviour.

* \#3352 Allow named scopes named "open" to work through 1-n relations.

* \#3348 Fixing compounded indexes having the same keys with
  different directions. (Arthur Neves)

* \#2701 Fixing extra query on belongs_to binding. (Arthur Neves)

* \#3089 Allow demongoization of strings to floats (Daniel Libanori)

* \#3278 Counter cache should update the document in memory too. (Arthur Neves)

* \#3242 Has_many relation must use the inverse foreign_key. (Arthur Neves)

* \#3233 Don't double call validation callbacks when cascading children and
  relation validation is turned on.

* \#3197 Improvements in the calls to `aggregates` on root and embedded
  collections. (Wojciech Piekutowski)

* \#3144/\#3219 Fixing name colission on @_children ivar. (Arthur Neves)

* \#3088 Range field can accept a hash, which could be the attribute from the db.
  (Daniel Libanori)

* \#3116 Relations instance variables are now all prefixed with `_`.

* \#3093 Only flatten 1 level when atomically pushing arrays.

* \#3063 `Document#becomes` now properly sets base object on errors.
  (Adam Ross Cohen)

* \#3019 Atomic operations will no longer attempt to persist if the document
  is not persisted.

* \#2903 Removed unused string `to_a` extension.

## 3.1.7

### Resolved Issues

* \#3465 Fixed ambigous relation errors where inverse_of is set to nil.

* \#3414 Backkport skip and limit options on aggregation. (Wojciech Piekutowski)

* \#3469 Fix RegexpError: failed to allocate memory: /\./ on .hash_dot_syntax?  (Dmitry Krasnoukhov)

## 3.1.6

### Resolved Issues

* \#3337 Ensure localized fields map is cloned with inheritance.

* \#3262 Fixed atomic array operations on HABTM foreign key fields from turning
  single elements into arrays.

* \#3282 Fixed .timeless option to use a thread local instead of a class attribute.
  Also remove the timeless methods from all docs, and only add to timestamps docs.
  (Arthur Neves)

## 3.1.5

### Resolved Issues

* \#3231 Allow evolution of proxy documents to work in criteria.

* \#3247 Bump dependency on tzinfo to 0.3.29.

* \#3203 Fixed `index: true` specification for polymorphic relations.

* \#3192 Fixed aliased fields + localized fields combinations with
  validation. (Johnny Shields)

* \#3173 Fixed issues around many to many relations with custom primary keys.
  (Bowen Sun)

* \#3159 Upserting now properly flags documents as persisted.

* \#3137 Allow multiple `belongs_to` sets in a row with ids.

* \#3079 Embbed docs with paranoia parents, were losing the _id when
  reloading from db, as they didnt have the right persisted? value. (Arthur Neves)

* \#3081 Criteria's `method_missing` now checks if an array responds to the provided
  method before calling entries in order to not hit the database if a `NoMethodError`
  was to get raised.

* \#3068 Fixed spec runs on non standard MongoDB ports if `MONGOID_SPEC_PORT` is
  set.

* \#3047 Ensure `blank?` and `empty?` don't fall through method missing on criteria.

* Include updated_at on cache_key even when is a short timestamp (Arthur Neves)

## 3.1.4

### Resolved Issues

* \#3044 Ensure enumerable targets match arrays in case statements.

* \#3034 `first_or_create` on criterion now properly passes the block to create
  instead of calling after the document was created.

* \#3021 Removed `mongoid.yml` warning from initializer, this is now handled by
  the session configuration options.

* \#3018 Uniqueness validator now properly serializes values in its check.
  (Jerry Clinesmith)

* \#3011 Fixed aliased field support for uniqueness validation. (Johnny Shields)

* \#3008 Fixed subclasses not being able to inherit scopes properly when scope
  is added post class load. (Mike Dillon)

* \#2991 `Document.timeless` now properly scopes to the instance and not thread.

* \#2980 Dynamic fields now properly handle in place editing of hashes and
  arrays. (Matthew Widmann)

* \#2979 `pluck` no longer modifies the context in place. (Brian Goff)

* \#2970 Fixed counter cache to properly use the name of the relation if available
  then the inverse class name second if not.

* \#2959 Nested attributes will now respect `autosave: false` if defined on the
  relation.

* \#2944 Fixed uniqueness validation for localized fields when case insensitive
  is true. (Vladimir Zhukov)

## 3.1.3

### Resolved Issues

* Dont duplicate embedded documents when saving after calling becomes method.
  (Arthur Neves)

* \#2961 Reloading a mongoid.yml configuration now properly clears previously
  configured sessions.

* \#2937 Counts can now take a `true` argument to factor in skip and limit.
  (Arthur Neves)

* \#2921 Don't use type in identity map selection if inheritance is not
  in play. (Arthur Neves)

* \#2893 Removed memoization of collection name and database name so lambdas
  with `store_in` work properly when changing.

* \#2911 The `_destroy` attribute on 1-n relations when processing nested
  attributes can now be a string or symbol when passed an array.

* \#2886 Fixed namespacing issue with Rails generators.

* \#2885 Fixed touch for aliased fields. (Niels Ganser)

* \#2883 Allow cyclic relations to not raise mixed relation errors.

* \#2867 `pluck` now properly handles aliased fields.

* \#2862 Autosaving no longer performs extra unnecessary queries.
  (Arthur Neves)

## 3.1.2

### Resolved Issues

* \#2851 Fixed BigDecimal demongoization of NaN values. (nkem)

* \#2848 Fixed `touch` to work when usinng short timestamps. (Arthur Neves)

* \#2840 Fixed end-to-end `no_timeout` option handling.

* \#2826 Dynamic fields are now properly mongoized.

* \#2822 Marshal load of relations now properly reapplies extensions.

## 3.1.1

### Resolved Issues

* \#2839 Validations fixed to use the type cast value with the exception
  of the numericality validator. (Lailson Bandeira)

* \#2838 `store_in` options now properly merge instead of override.
  (Colin MacKenzie)

## 3.1.0

### New Features

* The minimum MongoDB requirement is now raised to 2.2, since we now
  depend on the aggregation framework.

* The minimum Active Model and Active Support dependencies have been
  raised to 3.2.

* \#2809 Relations can now specify a primary key to use instead of the
  id on foreign keys.

        class Person
          include Mongoid::Document
          field :username, type: String
          has_many :cats, primary_key: "username"
        end

        class Cat
          include Mongoid::Document
          belongs_to :person, primary_key: "username"
        end

* \#2804 $geoNear support has now been added to criteria.

        Bar.where(:likes.gt => 1000).geo_near([ 52, 13 ])
        Bar.geo_near([ 52, 13 ]).max_distance(0.5).spherical

* \#2799 Criteria#map can now accept a symbol of a field name as well as
  a block to perform a more optimized `map`. (Gosha Arinich)

        Band.where(:likes.gt => 1000).map(:name)

* \#2798 Aggregations (`sum`, `min`, `max`, `avg`) now use the
  aggregation framework instead of map/reduce. (Gosha Arinich)

* \#2776 MongoDB 2.4.x new index types are now supported: "2dsphere",
  "text", and "hashed". (Irakli Janiashvili)

* \#2767 $maxScan support from Origin is now supported. (Jonathan Hyman)

* \#2701 Cleanup up extra excessive database queries with 1-1 relations.

* \#2693 Custom collection names can be passed to the model generator.
  (Subhash Bhushan)

        rails g model band --collection=artists

* \#2688 `Model.create` and `Model.create!` now can take an array of
  attributes hashes to create multiple documents at once. If an array
  of attributes is provided then an array of documents is returned.

        Band.create([{ name: "Tool" }, { name: "Placebo" }])
        Band.create!([{ name: "Tool" }, { name: "Placebo" }])

* \#2670 Unsetting fields now accepts multiple fields instead of only 1.
  (Arthur Neves)

        band.unset(:name, :founded)
        Band.where(name: "Placebo").unset(:members, :origin)

* \#2669 Passing a block to `Criteria#new` now properly sends the
  block through to the model's contructor. (Arthur Neves)

* \#2667 `exists?` no longer hits the database in cases where we have
  the necessary information in memory.

* \#2665 Mongoid now supports a counter cache for `belongs_to`
  relations. (Arthur Neves)

        class Band
          include Mongoid::Document
          belongs_to :label, counter_cache: "b_count"
        end

        class Album
          include Mongoid::Document
          belongs_to :band, counter_cache: true
        end

* \#2662 Embedded documents that have `belongs_to` relations may now
  eager load them.

* \#2657 Logger getter and setter convenience methods have been
  added to the `Config` module. (Arthur Neves)

* \#2615 Index options can now take a specific database name if the
  indexes are only to exist in a database other than the default.

        class Band
          include Mongoid::Document
          index name: 1, { database: "another_db" }
        end

* \#2613 Procs can now be provided as values to `store_in`:

        class Band
          include Mongoid::Document
          store_in database: ->{ Thread.current[:database] }
        end

* \#2609 Pass through batch_size option to query. (Martin Mauch)

* \#2555 Passing hashes to `find` when the documents id is of type hash
  now properly works. (Szymon Kurcab)

* \#2545 The `$` positional operator is used for update selectors on
  embedded documents that are nested 1 level deep, when appropriate.

* \#2539 `Mongoid.models` now tracks all models in the application for more
  accurate determination of models for things such as indexing rake tasks.
  (Ara Howard)

* \#2525 Added the ability to have short timestamped fields with aliases. This
  sets timestamp fields as `c_at` and `u_at` that are also aliased as
  `created_at` and `updated_at` for convenience. (Rodrigo Saito)

        class Band
          include Mongoid::Document
          include Mongoid::Timestamps::Short # For c_at and u_at.
        end

        class Band
          include Mongoid::Document
          include Mongoid::Timestamps::Created::Short # For c_at only.
        end

        class Band
          include Mongoid::Document
          include Mongoid::Timestamps::Updated::Short # For u_at only.
        end

* \#2465 Documents now have an `attribute_before_type_cast` for proper
  handling of validations. (Gerad Suyderhoud)

* \#2443 `expire_after_seconds` is now a valid index option
  (http://docs.mongodb.org/manual/core/indexes/#ttl-indexes,
   http://docs.mongodb.org/manual/tutorial/expire-data/).

        class Event
          include Mongoid::Document
          field :created_at, type: DateTime
          index({ created_at: 1 }, { expire_after_seconds: 3600 })
        end

* \#2373 Relations with the `touch: true` option will now be automatically
  touched when the child document is created or destroyed.

* Added `Document.first_or_create!` and `Criteria#first_or_create!`. This
  raises a validations error if creation fails validation.

        Band.where(name: "Depeche Mode").first_or_create!
        Band.where(name: "Tool").first_or_create!(active: true)

* Added `Document.first_or_initialize` and `Criteria#first_or_initialize`.
  This is the same as `first_or_create` but initializes a new (unpersisted)
  document if none is found.

        Band.where(name: "Depeche Mode").first_or_initialize
        Band.where(name: "Tool").first_or_initialize(active: true)

* Added `Model.pluck` and `Criteria#pluck` similar to Active Record's, which
  returns an array of values for the provided field. (Jason Lee)

        Band.where(name: "Depeche Mode").pluck(:_id)
        Band.where(name: "Tool").pluck(:likes)

* \#2324 Embeds many relations now properly handle `delete_if`.

* \#2317 Added `Document.first_or_create` and `Criteria#first_or_create`.
  This will return the first matching document or create one with additional
  attributes if one does not exist. (incorvia)

        Band.where(name: "Depeche Mode").first_or_create
        Band.where(name: "Tool").first_or_create(active: true)

* \#2292 Added `Model.each_with_index`.

* \#2285 `Config.load_configuration` is now public for those who want to instantiate
  settings directly from a hash.

* \#2275 Added rake task `db:mongoid:purge` that will drop all collections with
  the exception of the system collections in the default database.

* \#2257 `after_find` callbacks have been added for when documents are returned
  from the database.

        class Band
          include Mongoid::Document

          after_find do |doc|
            # Some logic here.
          end
        end

* \#2223 Allow to find documents by javascript with parameters that are
  protected from javascript injection via `Model.for_js`.

        Band.for_js("this.name = param", param: "Tool")
        Band.where(:likes.gt => 1000).for_js("this.likes < this.follows")

* \#2197 When providing session configuration with no ports, Mongoid will now
  default these to 27017.

* \#2180 1-n and n-n relations now support before/after add/remove callbacks.
  (Rodrigo Saito)

        class Band
          include Mongoid::Document

          embeds_many :albums, after_add: :notify_labels
          has_many :followers, before_remove: ->(band, follower){ notify_unfollow(follower) }
        end

* \#2157 `Criteria#update` and `Criteria#update_all` now serialize values
  according to their field type, if a field is defined.

* \#2022 Custom callbacks can now register themselves for use with observers
  by using the `observable` macro.

        class Band
          include Mongoid::Document

          define_model_callbacks :notification
          observable :notification
        end

        class BandObserver < Mongoid::Observer

          def before_notification(band)
            #...
          end

          def after_notification(band)
            #...
          end
        end

* \#1766 Many to many relations will not touch the database if the foreign key
  is an empty array.

* \#1564 Many to many foreign keys now have the default set lazily only if the
  relation has been accessed. This avoids storing empty arrays if the relation
  has not been touched.

### Resolved Issues

* \#2730 Calling sort on a context properly updates the context's criteria.
  (Arthur Neves)

* \#2719 `distinct` is now available at the class level.

        Band.distinct(:name)

* \#2714 Overriding sessions when the new session has a different database will
  now properly switch the database at runtime as well.

* \#2697 Eager loading fixed when including multiple models that inherit from
  the same class. (Kirill Lazarev)

* \#2664 In memory sorting of embedded documents now properly works when
  multiple fields are provided. (Neer Friedman)

## 3.0.24

### Resolved Issues

* \#2879 `remove_attribute` on new documents no longer creates an unnecessary
  $unset operation.

## 3.0.23

### Resolved Issues

* \#2851 Fixed BigDecimal demongoization of NaN values. (nkem)

* \#2841 Calling `delete_all` or `destroy_all` on an embeds many when in the
  middle of a parent update will now properly execute the deletion.
  (Arthur Neves)

* \#2835 Fixed clearing of persistence options in uniqueness validator.

* \#2826 Dynamic fields are now properly mongoized.

* \#2822 Marshal load of relations now properly reapplies extensions.

* \#2821 Autosaved relations should be duped in inheriting classes.

## 3.0.22

### Resolved Issues

* \#2812 Fixed criteria on many to many relations when the base document is
  destroyed and the foreign key has not yet been lazy evaluated.

* \#2796 Don't cascade changes on has_many relations when assigning with
  a delete.

* \#2795 Fix precision on time conversions. (Tom de Bruijn)

* \#2794 Don't autobuild when reading a relation for validation.

* \#2790 `becomes` now copies embedded documents even if they were protected
  by mass assignment.

* \#2787 Allow `becomes` to replace the document in the identity map.

* \#2786 Fixed regressed cascading callbacks on destroy not firing.

* \#2784 Fixed uniqueness validation properly getting added to subclasses.
  (Takeshi Akima)

## 3.0.21

### Resolved Issues

* \#2781 / * \#2777 - Fixed issue with serialization of `DateTime` that was
  only present in Rails environments.

## 3.0.20

### Resolved Issues

* \#2774 Ensure validations macros for uniqueness, presence, and associated
  are also available at the instance level.

* \#2772 Localized fields are now properly handled when cloning a document.

* \#2758 `Mongoid.create_indexes` does not fail when cannot constantize class.
  (Arthur Neves)

* \#2743 Persistence options are no longer cleared when loading revisions.
  (Arthur Neves)

* \#2741 Fix time mongoization usec rounding errors on MRI and JRuby.

* \#2740 Support integer keys in hash fields when using `read_attribute` with
  dot notation.

* \#2739 Ensure integer deserialization properly casts to integers.

* \#2733 Many to many relations with `inverse_of: nil` do not persist the
  inverse relation on `<<` or `push` if the document is already persisted.

* \#2705 Fixed logic around when children can be added to the cascading
  callbacks list.

## 3.0.19

### Resolved Issues

* Released to revert the changes in \#2703.

## 3.0.18

### Resolved Issues

* \#2707 Calling `find_or_create_by` or `find_by_initialize_by` off a relation
  with a chained criteria or scope now properly keeps the relations intact on
  the new or found document.

* \#2699 Resetting a field now removes the name from the changed attributes
  list. (Subhash Bhushan)

* \#2683 Aliased fields are now supported when executing atomic operations from
  criteria. (Arthur Neves)

* \#2678 Calling `Criteria#sum` with no matching documents returns `0` instead
  of `nil`.

* \#2671 Matchers now correctly handle symbol keys. (Jonathan Hyman)

## 3.0.17

### Resolved Issues

* \#2686 Fixed the broken Moped dependency - Moped now must be at least at
  version 1.2.0.

## 3.0.16

### Resolved Issues

* \#2661 Implement instance level `model_name` for documents.

* \#2651 Ensure `Criteria#type` works properly with both symbol and string
  keys in the selector.

* \#2647 Ensure `deleted?` and `destroyed?` on paranoid documents return the
  same value.

* \#2646 Set unloaded doc in memory on enumerable targets before yielding to
  the block.

* \#2645 Take caching into consideration when asking for counts.
  (Arthur Nogueira Neves)

* \#2642 Don't batch push empty arrays on embedded documents. (Laszlo Bacsi)

* \#2639 Avoid extra unnecesary queries on new records when building relations
  off of them.

* \#2638 When a criteria is eager loading, calling `first` or `last` then
  iterating the entire results properly eager loads the full request.

* \#2618 Validating uniqueness now always uses string consistency by default.

* \#2564 Fixed infinite recursion for cases where a relation getter was
  overridden and called the setter from that method.

* \#2554 Ensure `unscoped` on an `embeds_many` does not include documents
  flagged for destruction.

## 3.0.15

### Resolved Issues

* \#2630 Fix cascading when the metadata exists but no cascade defined.

* \#2625 Fix `Marshal.dump` and `Marshal.load` of proxies and criteria
  objects.

* \#2619 Fixed the classes returned by `observed_classes` on an observer
  when it is observing custom models.

* \#2612 `DocumentNotFound` errors now expose the class in the error
  instance.

* \#2610 Ensure calling `first` after a `last` that had sorting options resets
  the sort.

* \#2604 Check pulls and pushes for conflicting updates. (Lucas Souza)

* \#2600 Instantiate the proper class type for attributes when using
  multi parameter attributes. (xxswingxx)

* \#2598 Fixed sorting on localized fields with embedded docs.

* \#2588 Block defining methods for dynamic attributes that would be invalid
  ruby methods. (Matt Sanford)

* \#2587 Fix method clash with `belongs_to` proxies when resetting relation
  unloaded criteria.

* \#2585 Ensure session configuration options get passed to Moped as symbols.

* \#2584 Allow map/reduce to operate on secondaries if output is set to `inline`.

* \#2582 Ensure `nil` session override can never cause to access a session with
  name `nil`.

* \#2581 Use strong consistency when reloading documents. (Mark Kremer)

## 3.0.14

### Resolved Issues

* \#2575 Prevent end of month times from rounding up since floats are not
  precise enough to handle usec. (Steve Valaitis)

* \#2573 Don't use i18n for inspection messages.

* \#2571 Remove blank error message from locales. (Jordan Elver)

* \#2568 Fix uniqueness validation for lacalized fields when a scope is also
  provided.

* \#2552 Ensure `InvalidPath` errors are raised when embedded documents try to
  get paths from a root selector.

## 3.0.13

### Resolved Issues

* \#2548 Fix error when generating config file with a fresh app with Unicorn in
  the gemset.

## 3.0.12

### Resolved Issues

* \#2542 Allow embedded documents using `store_as` to properly alias in
  criteria.

* \#2541 Ensure that the type change is correct when upcasting/downcasting a
  document via `Document#becomes` (Łukasz Bandzarewicz)

* \#2529 Fields on subclasses that override fields in the parent where both have
  defaults with procs now properly override the default in the subclass.

* \#2528 Aliased fields need to be duped when subclassing.

* \#2527 Ensure removal of docs in a `has_many` does a multi update when setting
  to an empty array.

## 3.0.11

### Resolved Issues

* \#2522 Fixed `Criteria#with` to return the criteria and not the class.

* \#2518 Fix unit of work call for the identity map when using Passenger.

* \#2512 Ensure nested attributes destroy works with the delayed destroys
  introduced in 3.0.10 when multiple levels deep.

* \#2509 Don't hit identity map an extra time when the returned value is an
  empty hash. (Douwe Maan)

## 3.0.10

### Resolved Issues

* \#2507 Ensure no extra db hits when eager loading has a mix of parents
  with and without docs. (Douwe Maan)

* \#2505 Ensure `update` and `update_all` from criteria properly handle
  aliased fields. (Dmitry Krasnoukhov)

* \#2504 `Model#becomes` properly keeps the same id.

* \#2498 Criteria now properly pass provided blocks though `method_missing`.

* \#2496 Embedded documents that were previously stored without ids now
  properly update and get assigned ids from within Mongoid.

* \#2494 All explicit atomic operations now properly respect aliased fields.

* \#2493 Use `Class#name` instead of `Class#model_name` when setting
  polymorphic types in case `model_name` has been overridden.

* \#2491 Removed unnecessary merge call in cascadable children.

* \#2485 Removing indexes now always uses strong consistency.

* \#2483 Versioning now handles localized fields. (Lawrence Curtis)

* \#2482 Store find parameters in the `DocumentNotFound` error.

* \#2481 Map/reduce aggregations now properly handle Mongo's batching of
  reduce jobs in groups of 100 with the state being passed through on the
  count.

* \#2476 Handle skip and limit outside of range on embeds_many relations
  gracefully.

* \#2474 Correctly detach 1-1 relations when the child is not yet loaded.
  (Kostyantyn Stepanyuk)

* \#2451 `relation.deleted` on embedded paranoid documents now works properly
  again.

* \#2472 Ensure `update_all` on embedded relations works properly when nothing
  is actually going to be updated.

* \#2469 Nullified documents on relations are now able to be re-added with the
  same in memory instance.

* \#2454 `Model#as_document` properly allows changes from having a relation to
  the relation being removed. (James Almond)

* \#2445 Mongoid middleware now properly supports both normal and streamed
  responses and properly clears the identity map for either.

* \#2367 Embedded documents that are to be deleted via nested attributes no
  longer become immediately removed from the relation in case the parent
  validation fails. Instead, they get flagged for destruction and then the
  removal occurs upon the parent passing validation and going to persist.

  Note this is a behaviour change, but since the API does not change and
  the previous behaviour was incorrect and did not match AR this was able
  to go into a point release.

## 3.0.9

### Resolved Issues

* \#2463 Fixed the broken `rails g mongoid:config` from a fresh repo.

* \#2456 The descendants cache is now reset when the document is inherited
  again. (Kostyantyn Stepanyuk)

* \#2453 `Model#write_attribute` now properly works with aliased fields.
  (Campbell Allen)

* \#2444 Removed extra dirty methods creation call. (Kostyantyn Stepanyuk)

* \#2440/\#2435 Pass mass assignment options down to children when setting via
  nested attributes or embedded documents.

* \#2439 Fixed memory leak in threaded selection of returned fields.
  (Tim Olsen)

* mongoid/moped\#82 Aliased fields now work with `Criteria#distinct`.

* \#2423 Fixed embedded document's `update_all` to perform the correct $set
  when using off a criteria.

* \#2414 Index definitions now respect aliased fields.

* \#2413 Enumerable targets now properly return enumerators when no blocks
  are provided. (Andrew Smith)

* \#2411 BigDecimal fields are properly stored as strings when mongoizing
  integers and floats.

* \#2409 Don't warn about missing mongoid.yml if configured programatically.

* \#2403 Return false on `update_all` of an embeds many with no documents.

* \#2401 Bring back the ability to merge a criteria with a hash.

* \#2399 Reject blank id values on has_many `Model#object_ids=`.
  (Tiago Rafael Godinho)

* \#2393 Ensure `inverse_of` is respected when using polymorphic relations.

* \#2388 Map/reduce properly uses `sort` instead of `orderby` in the execution
  of the command. (Alex Tsibulya)

* \#2386 Allow geo haystack and bits parameters in indexes. (Bradley Rees)

* \#2380 `Model#becomes` now properly copies over dirty attributes.

* \#2331 Don't double push child documents when extra saves are called in an
  after_create callback.

## 3.0.8 (Yanked)

## 3.0.6

### Resolved Issues

* \#2375 Uniqueness validation scoping now works with aliased fields.

* \#2372 Ensure that all atomic operations mongoize values before executing.

* \#2370 Paranoid documents now properly don't get deleted when using
  `dependent: :restrict` and an exception is raised.

* \#2365 Don't do anything when trying to replace an embeds_one with the same
  document.

* \#2362 Don't store inverse of field values in the database when they are not
  needed. (When there is not more than one polymorphic parent defined on the
  same class).

* \#2360 Cloning documents should ignore mass assignment protection rules.

* \#2356 When limiting fields returned in queries via `only` ensure that the
  limitation is scoped to the model.

* \#2353 Allow `update_attribute` to properly handle aliased fields.

* \#2348 Conversion of strings to times should raise an arugment error if the
  string is invalid. (Campbell Allen)

* \#2346 Ensure `belongs_to` relations are evolvable when passed the proxy and
  not the document.

* \#2334 Fixed aggregation map/reduce when fields sometimes do not exist.
  (James McKinney)

* \#2330 Fixed inconsistency of #size and #length on criteria when the documents
  have been iterated over with a limit applied.

* \#2328 Ensure ordering is applied on all relation criteria if defined.

* \#2327 Don't execute callbacks from base document if the document cannot execute
  them.

* \#2318 Ensure setting any numeric on a Float field actually sets it as a float,
  even if the number provided is an integer.

## 3.0.5

### Resolved Issues

* \#2313 Fixed deserialization of `nil` `TimeWithZone` fields. (nagachika)

* \#2311 `Document#changes` no longer returns `nil` values for Array and Hash
  fields that were only accessed and didn't actually change. Regression from 2.4.x.

* \#2310 Setting a many to many duplicate successively in memory no longer clears
  the inverse foreign keys.

* \#2309 Allow embeds_one relations to be set with hashes more than just the
  initial set.

* \#2308 Ensure documents retrieved via `#find` on `has_many` and
  `has_and_belongs_to_many` relations are kept in memory.

* \#2304 Default scopes now properly merge instead of overwrite when more
  than one is defined as per expectations with AR.  (Kirill Maksimov)

* \#2300 Ensure reloading refreshes the document in the identity map.

* \#2298 Protect against many to many relations pulling a null set of ids.
   (Jonathan Hyman)

* \#2291 Fixed touch operations only to update the timestamp and the optional
  field, no matter what the other changes on the document are.

* \#1091 Allow presence validation to pass if the value is `false`.

## 3.0.4

### Resolved Issues

* \#2280 Fix synchronization of many-to-many relations when an ordering default
  scope exists on either side of the association.

* \#2278 `Criteria#update` now properly updates only the first matching document,
  where `Criteria#update_all` will update all matching documents. (no flag vs multi).

* \#2274 When loading models, warn if error is raised but continue processing.

* \#2272 Don't wipe selectors or options when removing the default scope for
  actual nil values. Must check if key exists as well.

* \#2266 Restored paranoid documents are no longer flagged as destroyed.
  (Mario Uher)

* \#2263 Ensure casting of non object id foreign keys on many to many relations
  happens in the initial set, not at validation time.

## 3.0.3

### Resolved Issues

* \#2259 Ensure subclassed documents can not be pulled from the identity map
  via an id of another document in the same collection with a parent or
  sibeling type.

* \#2254 $inc operations no longer convert all values to floats.

* \#2252 Don't fire autosave when before callbacks have terminated.

* \#2248 Improved the performance of `exists?` on criteria and relations.
  (Jonathan Hyman)

## 3.0.2

### Resolved Issues

* \#2244 Get rid of id mass assignment warnings in nested attributes.

* \#2242 Fix eager loading not to load all documents when calling first or
  last.

* \#2241 Map/reduce operations now always use strong consistency since they
  have the potential to write to collections, most of the time.

* \#2238 Ensure n-n foreign key fields are flagged as resizable to prevent
  `nil` -> `[]` changes when using `#only` and updating.

* \#2236 Keep the instance of the document in the validations exception
  accessible via `document` or `record`.

* \#2234 Ensure validations when document is getting persisted with custom
  options work properly with custom options, and do not clear them out if
  validation passes.

* \#2224 `Model#inc` now accepts `BigDecimal` values.

* \#2216 Fixed assignment of metadata on embeds one relations when setting
  multiple times in a row.

* \#2212 Ensure errors are cleared after a save with `validate: false` in all
  situations.

* \#2207 When eager loading ids the query must be duped to avoid multiple
  iteration problems not getting the required fields.

* \#2204 Raise an `InvalidIncludes` error when passing arguments to
  `Criteria.includes` that are invalid (not relations, or more than 1 level.)

* \#2203 Map/Reduce now works properly in conjunction with `Model#with`.

        Band.
          with(session: "secondary").
          where(:likes.gt => 100).
          map_reduce(map, reduce).
          out(inline: 1)

* \#2199 Autosave false is now respected when automatically adding
  presence validation. (John Nishinaga)

## 3.0.1

### Resolved Issues

* \#2191 Ensure proper visibility (private) for error message generation
  methods.

* \#2187 Ensure all levels of nested documents are serialized in json.

* \#2184 Allow names of relations that conflict with ruby core kernel
  methods to pass existence checks.

* \#2181 Ensure `.first` criteria sort by ascending ids, if no other
  sorting criteria was provided.

## 3.0.0

### New Features

* \#2151 When asking for metadata before persistence, Mongoid will now
  raise a `Mongoid::Errors::NoMetadata` error if the metadata is not
  present.

* \#2147 `Model#becomes` now copies over the embedded documents.

* A new callback has been introduced: `upsert`, which runs when calling
  `document.upsert` since Mongoid does not know if the document is to be
  treated as new or persisted. With this come the model callbacks:

        before_upsert
        after_upsert
        around_upsert

* \#2080/\#2087 The database or session that Mongoid persists to can now be
  overridden on a global level for cases where `Model#with` is not a viable
  option.

        Mongoid.override_database(:secondary)
        Mongoid.override_session(:secondary)

        Band.create(name: "Placebo") #=> Persists to secondary.
        band.albums.create #=> Persists to secondary.

    Note that this option is global and overrides for all models on the current
    thread. It is the developer's responsibility to remember to set this back
    to nil if you no longer want the override to happen.

        Mongoid.override_database(nil)
        Mongoid.override_session(nil)

* \#1989 Criteria `count`, `size` and `length` now behave as Active Record
  with regards to database access.

    `Criteria#count` will always hit the database to get the count.

    `Criteria#length` and `Criteria#size` will hit the database once if the
    criteria has not been loaded, and subsequent calls will return the
    cached value.

    If the criteria has been iterated over or loaded, `length` and `size`
    will never hit the db.

* \#1976 Eager loading no longer produces queries when the base query returns
  zero results.

* `Model.find_by` now accepts a block and will yield to the found document if
  it is not nil.

        Band.find_by(name: "Depeche Mode") do |band|
          band.likes = 100
        end

* \#1958/\#1798 Documents and `belongs_to` relations now support touch.

        class Band
          include Mongoid::Document
          include Mongoid::Timestamps::Updated
          belongs_to :label, touch: true
        end

    Update the document's updated_at timestamp to the current time. This
    will also update any touchable relation's timestamp as well.

        Band.first.touch

    Update a specific time field along with the udpated_at.

        Band.first.touch(:founded)

    This fires no validations or callbacks.

* Mongoid now supports MongoDB's $findAndModify command.

        Band.find_and_modify("$inc" => { likes: 1 })

        Band.desc(:name).only(:name).find_and_modify(
          { "$inc" => { likes: 1 }}, new: true
        )

* \#1906 Mongoid will retrieve documents from the identity map when
  providing multiple ids to find. (Hans Hasselberg)

* \#1903 Mongoid raises an error if provided a javascript expression
  to a where clause on an embedded collection. (Sebastien Azimi)

* Aggregations now adhere to both a Mongoid API and their enumerable
  counterparts where applicable.

        Band.min(:likes)
        Band.min do |a, b|
          a.likes <=> b.likes
        end

        Band.max(:likes)
        Band.max do |a, b|
          a.likes <=> b.likes
        end

    Note that when providing a field name and no block, a single numeric
    value will be returned, but when providing a block, a document will
    be returned which has the min/max value. This is since Ruby's
    Enumerable API dictates when providing a block, the matching element
    is returned.

    When providing a block, all documents will be loaded into memory.
    When providing a symbol, the execution is handled via map/reduce on
    the server.

* A kitchen sink aggregation method is now provided, to get everything in
  in a single call for a field.

        Band.aggregates(:likes)
        # =>
        #   {
        #     "count" => 2.0,
        #     "max" => 1000.0,
        #     "min" => 500.0,
        #     "sum" => 1500.0,
        #     "avg" => 750.0
        #   }

* A DSL off the criteria API is now provided for map/reduce operations
  as a convenience.

        Band.where(name: "Tool").map_reduce(map, reduce).out(inline: 1)
        Band.map_reduce(map, reduce).out(replace: "coll-name")
        Band.map_reduce(map, reduce).out(inline: 1).finalize(finalize)

* Mongoid now uses Origin for its Criteria API. See the Origin repo
  and API docs for the documentation.

* \#1861 Mongoid now raises an `AmbiguousRelationship` error when it
  cannot determine the inverse of a relation and there are multiple
  potential candidates. (Hans Hasselberg)

* You can now perform an explain directly from criteria.

        Band.where(name: "Depeche Mode").explain

* \#1856 Push on one to many relations can now be chained.

        band.albums.push(undertow).push(aenima)

* \#1842 MultiParameterAttributes now supported aliased fields.
  (Anton Orel)

* \#1833 If an embedded document is attempted to be saved with no
  parent defined, Mongoid now will raise a `Mongoid::Errors::NoParent`
  exception.

* Added an ORM-agnostic way to get the field names

        class Band
          include Mongoid::Document
          field :name, type: String
        end

        Band.attribute_names

* \#1831 `find_or_create_by` on relations now takes mass assignment
  and type options. (Tatsuya Ono)

        class Band
          include Mongoid::Document
          embeds_many :albums
        end

        band.albums.find_or_create_by({ name: "101" }, LP)

* \#1818 Add capability to choose the key where your `embeds_many` relation
  is stores. (Cyril Mougel)

        class User
          include Mongoid::Document
          field :name, type: String
          embeds_many :prefs, class_name: "Preference", store_as: 'my_preferences'
        end

        user.prefs.build(value: "ok")
        user.save
        # document saves in MongoDB as:
        # { "name" => "foo", "my_preferences" => [{ "value" => "ok" }]}

* \#1806 `Model.find_or_create_by` and `Model.find_or_initialize_by` can now
  take documents as paramters for belongs_to relations.

        person = Person.first
        Game.find_or_create_by(person: person)

* \#1774 Relations now have a :restrict option for dependent relations
  which will raise an error when attempting to delete a parent that
  still has children on it. (Hans Hasselberg)

        class Band
          include Mongoid::Document
          has_many :albums, dependent: :restrict
        end

        band = Band.first
        band.albums << Albums.first
        band.delete # Raises DeleteRestriction error.

* \#1764 Add method to check if field differs from the default value.

        class Band
          include Mongoid::Document
          field :name, type: String, default: "New"
        end

        band = Band.first
        band.name_changed_from_default?

* \#1759 Invalid fields error messages have been updated to show the
  source and location of the original method. The new message is:

        Problem:
          Defining a field named 'crazy_method' is not allowed.
        Summary:
          Defining this field would override the method 'crazy_method',
          which would cause issues with expectations around the original
          method and cause extremely hard to debug issues.
          The original method was defined in:
            Object: MyModule
            File: /path/to/my/module.rb
            Line: 8
        Resolution:
          Use Mongoid.destructive_fields to see what names are
          not allowed, and don't use these names. These include names
          that also conflict with core Ruby methods on Object, Module,
          Enumerable, or included gems that inject methods into these
          or Mongoid internals.

* \#1753/#1649 A setter and getter for has_many relations to set its
  children is now provided. (Piotr Jakubowski)

        class Album
          include Mongoid::Document
          has_many :engineers
        end

        class Engineer
          include Mongoid::Document
          belongs_to :album
        end

        album = Album.first
        engineer = Engineer.first
        album.engineer_ids = [ engineer.id ]
        album.engineer_ids # Returns the ids of the engineers.

* \#1741 Mongoid now provides a rake task to force remove indexes for
  environments where Mongoid manages the index definitions and the
  removal should be automated. (Hans Hasselberg)

        rake db:force_remove_indexes
        rake db:mongoid:force_remove_indexes

* \#1726 `Mongoid.load!` now accepts an optional second argument for the
  environment to load. This takes precedence over any environment variable
  that is set if provided.

        Mongoid.load!("/path/to/mongoid.yml", :development)

* \#1724 Mongoid now supports regex fields.

        class Rule
          include Mongoid::Document
          field :pattern, type: Regexp, default: /[^abc]/
        end

* \#1714/\#1706 Added better logging on index creation. (Hans Hasselberg)

    When an index is present on a root document model:

        Creating indexes on: Model for: name, dob.

    When an index is defined on an embedded model:

        Index ignored on: Address, please define in the root model.

    When no index is defined, nothing is logged, and if a bad index is
    defined an error is raised.

* \#1710 For cases when you don't want Mongoid to auto-protect the id
  and type attributes, you can set a configuration option to turn this
  off.

        Mongoid.protect_sensitive_fields = false

* \#1685 Belongs to relations now have build_ and create_ methods.

        class Comment
          include Mongoid::Document
          belongs_to :user
        end

        comment = Comment.new
        comment.build_user # Build a new user object
        comment.create_user # Create a new user object

* \#1684 Raise a `Mongoid::Errors::InverseNotFound` when attempting to
  set a child on a relation without the proper inverse_of definitions
  due to Mongoid not being able to determine it.

        class Lush
          include Mongoid::Document
          embeds_one :whiskey, class_name: "Drink"
        end

        class Drink
          include Mongoid::Document
          embedded_in :alcoholic, class_name: "Lush"
        end

        lush = Lush.new
        lush.whiskey = Drink.new # raises an InverseNotFound error.

* \#1680 Polymorphic relations now use `*_type` keys in lookup queries.

        class User
          include Mongoid::Document
          has_many :comments, as: :commentable
        end

        class Comment
          include Mongoid::Document
          belongs_to :commentable, polymorphic: true
        end

        user = User.find(id)
        user.comments # Uses user.id and type "User" in the query.

* \#1677 Support for parent separable polymorphic relations to the same
  parent class is now available. This only works if set from the parent
  side in order to know which relation the children belong to.
  (Douwe Maan)

        class Face
          include Mongoid::Document
          has_one :left_eye, class_name: "Eye", as: :visible
          has_one :right_eye, class_name: "Eye", as: :visible
        end

        class Eye
          include Mongoid::Document
          belongs_to :visible, polymorphic: true
        end

        face = Face.new
        right_eye = Eye.new
        left_eye = Eye.new
        face.right_eye = right_eye
        face.left_eye = left_eye
        right_eye.visible = face # Will raise an error.

* \#1650 Objects that respond to `to_criteria` can now be merged into
  existing criteria objects.

        class Filter
          def to_criteria
            # return a Criteria object.
          end
        end

        criteria = Person.where(title: "Sir")
        criteria.merge(filter)

* \#1635 All exceptions now provide more comprehensive errors, including
  the problem that occured, a detail summary of why it happened, and
  potential resolutions. Example:

        (Mongoid::Errors::DocumentNotFound)
        Problem:
          Document not found for class Town with
          id(s) [BSON::ObjectId('4f35781b8ad54812e1000001')].
        Summary:
          When calling Town.find with an id or array of ids,
          each parameter must match a document in the database
          or this error will be raised.
        Resolution:
          Search for an id that is in the database or set the
          Mongoid.raise_not_found_error configuration option to
          false, which will cause a nil to be returned instead
          of raising this error.

* \#1616 `Model.find_by` added which takes a hash of arugments to search
  for in the database. If no single document is returned a DocumentNotFound
  error is raised. (Piotr Jakubowski)

        Band.find_by(name: "Depeche Mode")

* \#1606 Mongoid now enables autosave, like Active Record, when adding
  an accepts_nested_attributes_for to a relation.

        class Band
          include Mongoid::Document
          has_many :albums
          accepts_nested_attributes_for :albums # This enables the autosave.
        end

* \#1477 Mongoid now automatically protects the id and type attributes
  from mass assignment. You can override this (not recommended) by redefining
  them as accessible.

        class Band
          include Mongoid::Document
          attr_accessible :id, :_id, :_type
        end

* \#1459 The identity map can be disabled now for specific code execution
  by passing options to the unit of work.

        Mongoid.unit_of_work(disable: :all) do
          # Disables the identity map on all threads for the block.
        end

        Mongoid.unit_of_work(disable: :current) do
          # Disables the identity map on the current thread for the block.
        end

        Mongoid.unit_of_work do
          # Business as usual.
        end

* \#1355 Associations now can have safety options provided to them on single
  document persistence operations.

        band.albums.with(safe: true).push(album)
        band.albums.with(safe: true).create(name: "Smiths")

        album.with(safe: true).create_producer(name: "Flood")

* \#1348 Eager loading is now supported on many-to-many relations.

* \#1292 Remove attribute now unsets the attribute when the document is
  saved instead of setting to nil.

        band = Band.find(id)
        band.remove_attribute(:label) # Uses $unset when the document is saved.

* \#1291 Mongoid database sessions are now connected to lazily, and are
  completely thread safe. If a new thread is created, then a new database
  session will be created for it.

* \#1291 Mongoid now supports any number of database connections as defined in
  the mongoid.yml. For example you could have a local single server db, a
  multi availablity zone replica set, and a shard cluster all in the same
  application environment. Mongoid can connect to any session at any point in
  time.

* \#1291 Mongoid now allows you to persist to whatever database or collection
  you like at runtime, on a per-query or persistence operation basis by using
  `with`.

        Band.with(collection: "artists").create(name: "Depeche Mode")
        band.with(database: "secondary).save!
        Band.with(collection: "artists").where(name: "Depeche Mode")

* \#1291 You can now configure on a per-model basis where its documents are
  stored with the new and improved `store_in` macro.

        class Band
          include Mongoid::Document
          store_in collection: "artists", database: "secondary", session: "replica"
        end

    This can be overridden, of course, at runtime via the `with` method.

* \#1212 Embedded documents can now be popped off a relation with persistence.

        band.albums.pop # Pop 1 document and persist the removal.
        band.albums.pop(3) # Pop 3 documents and persist the removal.

* \#1188 Relations now have existence predicates for simplified checking if the
  relation is blank or not. (Andy Morris)

        class Band
          include Mongoid::Document
          embeds_many :albums
          embeds_one :label
        end

        band = Band.new
        band.albums?
        band.has_albums?
        band.label?
        band.has_label?

* \#1188 1-1 relations now have an :autobuild option to indicate if the
  relation should automatically be build with empty attributes upon access
  where the relation currently does not exist. Works on embeds_one,
  embedded_in, has_one, belongs_to. (Andy Morris)

        class Band
          include Mongoid::Document
          has_one :label, autobuild: true
        end

        band = Band.new
        band.label # Returns a new label with empty attributes.

      When using existence checks, autobuilding will not execute.

        band = Band.new
        band.label? # Returns false, does not autobuild on a check.
        band.has_label? # Returns false, does not autobuild on a check.

* \#1081 Mongoid indexes both id and type as a compound index when providing
  `index: true` to a polymorphic belongs_to.

        class Comment
          include Mongoid::Document

          # Indexes commentable_id and commentable_type as a compound index.
          belongs_to :commentable, polymorphic: true, index: true
        end

* \#1053 Raise a `Mongoid::Errors::UnknownAttribute` instead of no method
  when attempting to set a field that is not defined and allow dynamic
  fields is false. (Cyril Mougel)

        Mongoid.allow_dynamic_fields = false

        class Person
          include Mongoid::Document
          field :title, type: String
        end

        Person.new.age = 50 # raises the UnknownAttribute error.

* \#772 Fields can now be flagged as readonly, which will only let their
  values be set when the document is new.

        class Band
          include Mongoid::Document
          field :name, type: String
          field :genre, type: String

          attr_readonly :name, :genre
        end

      Readonly values are ignored when attempting to set them on persisted
      documents, with the exception of update_attribute and remove_attribute,
      where errors will get raised.

        band = Band.create(name: "Depeche Mode")
        band.update_attribute(:name, "Smiths") # Raises ReadonlyAttribute error.
        band.remove_attribute(:name) # Raises ReadonlyAttribute error.


### Major Changes (Backwards Incompatible)

* Polymorphic relations can not have ids other than object ids. This is
  because Mongoid cannot properly figure out in an optimized way what the
  various classes on the other side of the relation store their ids as, as
  they could potentially all be different.

  This was not allowed before, but nowhere was it explicitly stated.

* \#2039 Validating presence of a relation now checks both the relation and
  the foreign key value.

* Indexing syntax has changed. The first parameter is now a hash of
  name/direction pairs with an optional second hash parameter for
  additional options.

      Normal indexing with options, directions are either 1 or -1:

        class Band
          include Mongoid::Document
          field :name, type: String

          index({ name: 1 }, { unique: true, background: true })
        end

      Geospacial indexing needs "2d" as its direction.

        class Venue
          include Mongoid::Document
          field :location, type: Array

          index location: "2d"
        end

* Custom serializable fields have revamped. Your object no longer should
  include `Mongoid::Fields::Serializable` - instead it only needs to
  implement 3 methods: `#mongoize`, `.demongoize` and `.evolve`.

      `#mongoize` is an instance method that transforms your object into
      a mongo-friendly value.

      `.demongoize` is a class method, that can take some data from mongo
      and instantiate and object of your custom type.

      `.evolve` is a class method, that can take any object, and
      transform it for use in a `Mongoid::Criteria`.

      An example of an implementation of this for `Range`:

        class Range

          def mongoize
            { "min" => first, "max" => last }
          end

          class << self

            def demongoize(object)
              Range.new(object["min"], object["max"])
            end

            def evolve(object)
              { "$gte" => object.first, "$lte" => object.last }
            end
          end
        end

* `Document#changes` is no longer a hash with indifferent access.

* `after_initialize` callbacks no longer cascade to children if the option
  is set.

* \#1865 `count` on the memory and mongo contexts now behave exactly the
  same as Ruby's `count` on enumerable, and can take an object or a block.
  This is optimized on the mongo context not to load everything in memory
  with the exception of passing a block.

        Band.where(name: "Tool").count
        Band.where(name: "Tool").count(tool) # redundant.
        Band.where(name: "Tool") do |doc|
          doc.likes > 0
        end

    Note that although the signatures are the same for both the memory and
    mongo contexts, it's recommended you only use the block syntax for the
    memory context since the embedded documents are already loaded into
    memory.

    Also note that passing a boolean to take skip and limit into account
    is no longer supported, as this is not necessarily a useful feature.

* The `autocreate_indexes` configuration option has been removed.

* `Model.defaults` no longer exists. You may get all defaults with a
  combination of `Model.pre_processed_defaults` and
  `Model.post_processed_defaults`.

        Band.pre_processed_defaults
        Band.post_processed_defaults

* `Model.identity` and `Model.key` have been removed. For custom ids,
  users must now override the _id field.

    When the default value is a proc, the default is applied *after* all
    other attributes are set.

        class Band
          include Mongoid::Document
          field :_id, type: String, default: ->{ name }
        end

    To have the default applied *before* other attributes, set `:pre_processed`
    to true.

        class Band
          include Mongoid::Document
          field :_id,
            type: String,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new.to_s }
        end

* Custom application exceptions in various languages has been removed,
  along with the `Mongoid.add_language` feature.

* Mongoid no longer supports 1.8. MRI 1.9.3 and higher, or JRuby 1.6 and
  higher in 1.9 mode are only supported.

* \#1734 When searching for documents via `Model.find` with multiple ids,
  Mongoid will raise an error if not *all* ids are found, and tell you
  what the missing ones were. Previously the error only got raised if
  nothing was returned.

* \#1675 Adding presence validation on a relation now enables autosave.
  This is to ensure that when a new parent object is saved with a new
  child and marked is valid, both are persisted to ensure a correct
  state in the database.

* \#1491 Ensure empty translations returns an empty hash on access.

* \#1484 `Model#has_attribute?` now behaves the same as Active Record.

* \#1471 Mongoid no longer strips any level of precision off of times.

* \#1475 Active support's time zone is now used by default in time
  serialization if it is defined.

* \#1342 `Model.find` and `model.relation.find` now only take a single or
  multiple ids. The first/last/all with a conditions hash has been removed.

* \#1291 The mongoid.yml has been revamped completely, and upgrading
  existing applications will greet you with some lovely Mongoid specific
  configuration errors. You can re-generate a new mongoid.yml via the
  existing rake task, which is commented to an insane degree to help you
  with all the configuration possibilities.

* \#1291 The `persist_in_safe_mode` configuration option has been removed.
  You must now tell a database session in the mongoid.yml whether or not
  it should persist in safe mode by default.

        production:
          sessions:
            default:
              database: my_app_prod
              hosts:
                - db.app.com:27018
                - db.app.com:27019
              options:
                consistency: :eventual
                safe: true

* \#1291 `safely` and `unsafely` have been removed. Please now use `with`
  to provide safe mode options at runtime.

        Band.with(safe: true).create
        band.with(safe: { w: 3 }).save!
        Band.with(safe: false).create!

* \#1270 Relation macros have been changed to match their AR counterparts:
  only :has_one, :has_many, :has_and_belongs_to_many, and :belongs_to
  exist now.

* \#1268 `Model#new?` has been removed, developers must now always use
  `Model#new_record?`.

* \#1182 A reload is no longer required to refresh a relation after setting
  the value of the foreign key field for it. Note this behaves exactly as
  Active Record.

    If the id is set, but the document for it has not been persisted, accessing
    the relation will return empty results.

    If the id is set and its document is persisted, accessing the relation
    will return the document.

    If the id is set, but the base document is not saved afterwards, then
    reloading will return the document to its original state.

* \#1093 Field serialization strategies have changed on Array, Hash, Integer
  and Boolean to be more consistent and match AR where appropriate.

    Serialization of arrays calls `Array.wrap(object)`
    Serialization of hashes calls `Hash[object]` (to_hash on the object)
    Serialization of integers always returns an int via `to_i`
    Serialization of booleans defaults to false instead of nil.

* \#933 `:field.size` has been renamed to `:field.count` in criteria for
  $size not to conflict with Symbol's size method.

* \#829/\#797 Mongoid scoping code has been completely rewritten, and now
  matches the Active Record API. With this backwards incompatible change,
  some methods have been removed or renamed.

    Criteria#as_conditions and Criteria#fuse no longer exist.

    Criteria#merge now only accepts another object that responds to
    `to_criteria`.

    Criteria#merge! now merges in another object without creating a new
    criteria object.

        Band.where(name: "Tool").merge!(criteria)

    Named scopes and default scopes no longer take hashes as parameters.
    From now on only criteria and procs wrapping criteria will be
    accepted, and an error will be raised if the arguments are incorrect.

        class Band
          include Mongoid::Document

          default_scope ->{ where(active: true) }
          scope :inactive, where(active: false)
          scope :invalid, where: { valid: false } # This will raise an error.
        end

    The 'named_scope' macro has been removed, from now on only use 'scope'.

    Model.unscoped now accepts a block which will not allow default scoping
    to be applied for any calls inside the block.

        Band.unscoped do
          Band.scoped.where(name: "Ministry")
        end

    Model.scoped now takes options that will be set directly on the criteria
    options hash.

        Band.scoped(skip: 10, limit: 20)

* \#463 `Document#upsert` is no longer aliased to `Document#save` and now
  actually performs a proper MongoDB upsert command when called. If you
  were using this method before and want the same behaviour, please switch
  to `save`.

        band = Band.new(name: "Tool")
        band.upsert #=> Inserts the document in the database.
        band.name = "Placebo"
        band.upsert #=> Updates the existing document.

### Resolved Issues

* \#2166 `Criteria#from_map_or_db` strips type selection when eager loading
  since it will check if the type is correct after.

* \#2129 Fixed sorting for all fields on embeds many relations.

* \#2124 Fixed default scope and deleted scope on paranoid documents.

* \#2122 Allow embedded documents to sort on boolean fields.

* \#2119 Allow `Criteria#update_all` to accept atomic ops and normal sets.

* \#2118 Don't strip any precision during `DateTime` -> `Time` conversions.

* \#2117 Ensure embeds one relations have callbacks run when using nested
  attributes.

* \#2110 `Model#touch` now works properly on embedded documents.

* \#2100 Allow atomic operations to properly execute on paranoid documents
  that have a deleted_at set.

* \#2089 Allow proper separation of mongoization and evolving with respect to
  foreign keys.

* \#2088 Allow finds by string ids to pull from the identity map if the ids
  are stored as object ids.

* \#2085 Allow demongoization of floats and ints to big decimals.

* \#2084 Don't cascade if metadata does not exist.

* \#2078 Calling `Model#clone` or `Model#dup` now properly sets attributes
  as dirty.

* \#2070 Allow for updated_at to be overridden manually for new documents that
  also have a created_at.

* \#2041 Don't hit the database multiple times on relation access after an
  eager load returned zero documents.

* \#1997 Cascading callbacks should be able to halt the callback chain when
  terminating.

* \#1972 `added`, `loaded`, and `unloaded` can now be valid scope names on a
  document that is part of a 1-n relation.

* \#1952/#1950 `#all_in` behaviour on embedded documents now properly matches
  root documents when passing an empty array. (Hans Hasselberg)

* \#1941/#1939 `Model.find_by` now returns nil if raise not found error is
  set to false. (Hans Hasselberg)

* \#1859/#1860 `Model#remove_attribute` now properly unsets on embedded
  documents. (Anton Onyshchenko)

* \#1852 Ensure no infinite recursion on cascading callbacks. (Ara Howard)

* \#1823 `Relation#includes?` now properly works with identity map enabled.

* \#1810 `Model#changed?` no longer returns true when hash and array fields
  have only been accessed.

* \#1876/\#1782 Allow dot notation in embeds many criteria queries.
  (Cyril Mougel)

* \#1745 Fixed batch clear to work within attribute setting.

* \#1718 Ensure consistency of #first/#last in relations - they now always
  match first/last in the database, but opts for in memory first.

* \#1692/\#1376 `Model#updateattributes` and `Model#update_attributes!` now
  accept assignment options. (Hans Hasselberg)

* \#1688/\#1207 Don't require namespacing when providing class name on
  relation macros inside the namespace. (Hans Hasselberg)

* \#1665/\#1672 Expand complex criteria in nested criteria selectors, like
  \#matches. (Hans Hasselberg)

* \#1335 Don't add id sorting criteria to first/last is there is already
  sorting options on the criteria.

* \#1321 Referenced many enumerable targets are now hash-backed, preventing
  duplicates in a more efficient manner.

* \#1135 DateTimes now properly get time zones on deserialization.

* \#1031 Mongoid now serializes values in Array fields to their proper
  Mongo-friendly values when possible.

* \#685 Attempting to use versioning with embedded documents will now
  raise a proper error alerting the developer this is not allowed.

## 2.6.0

### New Features

* \#2709 Backported the `touch` functionality from Mongoid 3.

## 2.5.2

### Resolved Issues

* \#2502 Fixed cache key to properly handle when the document does not
  include `Mongoid::Timestamps::Updated`. (Arthur Nogueira Neves)

## 2.5.1

### Resolved Issues

* \#2492 Backport cascading callbacks performance and memory fixes from
  3.0.0-stable.

* \#2464 Backport the nested attributes fix for keeping many relations in
  memory when updating attributes. (Chris Thompson)

## 2.5.0

### New Features

* This is a release to support the 1.7.0 and higher Mongo and BSON gems and
  resolves issues that kept the 2.4.x series locked below 1.6.2

## 2.4.12

### Resolved Issues

* \#2178 Ensure destroy callbacks are run post replacement of an embeds one
  relation.

* \#2169 Allow saves to pass when documents are destroyed after the save
  in a callback.

* \#2144 Uniqueness validation on paranoid documents now properly scopes.

* \#2127 Don't unbind parents of embedded documents mid nested
  attributes deletion.

## 2.4.11

### Resolved Issues

* This release forces a cap on the mongo driver version at 1.6.2 due to
  changes in the `Mongo::Connection.from_uri` API not allowing valid
  connection options anymore.

* \#2040 Fixed bad interpolation for locale presence validation.

* \#2038 Allow inverse relations to be determined by foreign keys alone
  if defined on both sides, not just an inverse_of declaration.

* \#2023 Allow serilialization of dynamic types that conflict with core
  Ruby methods to still be serialized.

* \#2008 Presence validation should hit the db to check validity if the
  relation in memory is blank.

* \#2006 Allow excluding only the _id field post execution of an #only call.

## 2.4.10

### Resolved Issues

* \#2003 Don't fail on document generation when an embedded document was
  stored as nil in the database.

* \#1997 Don't delete paranoid embedded docs via nested attributes when
  a before_destroy callback returns false.

* \#1994 `dependent: :delete` only hits the database once now for one to
  many and many to many relations instead of once for each document.

* \#1987 Don't double-insert documents into identity map when eager loading
  twice inside the unit of work.

* \#1953 Uniqueness validation now works on localized fields.

* \#1936 Allow setting n levels deep embedded documents atomically without
  conflicting mods when not using nested attributes or documents themselves
  in an update call from the parent.

* \#1957/\#1954 Ensure database name is set with inheritance.
  (Hans Hasselberg)

## 2.4.9

### Resolved Issues

* \#1943 Ensure numericality validation works for big decimals.

* \#1938 Length validation now works with localized fields.

* \#1936 Conflicting pushes with other pushes is now properly handled.

* \#1933 `Proxy#extend` should delegate through to the target, where
  extending the proxy itself is now handled through `Proxy#proxy_extend`.

* \#1930 Ensure complex criteria are expanded in all where clauses.
  (Hans Hasselberg)

* \#1928 Deletion of embedded documents via nested attributes now performs
  a $pull with id match criteria instead of a $pullAll to cover all cases.
  Previously newly added defaults to documents that had already persisted
  could not be deleted in this matter since the doc did not match what was
  in the database.

* \#1924/\#1917 Fix pushing to embedded relations with default scopes not
  scoping on the new document. (Hans Hasselberg)

* \#1922/\#1919 Dropping collections unmemoizes the internally wrapped
  collection, in order to ensure when defining capped collections that
  they are always recreated as capped. (Hans Hasselberg)

* \#1916/\#1913 Uniqueness validation no longer is affected by the default
  scope. (Hans Hasselberg)

* \#1943 Ensure numericality validation works for big decimals.

## 2.4.8

### Resolved Issues

* \#1892 When getting not master operation error, Mongoid should reconnect
  before retrying the operation.

* \#1887 Don't cascade callbacks to children that don't have the callback
  defined.

* \#1882 Don't expand duplicate id criterion into an $and with duplicate
  selections.

* \#1878 Fixed default application values not to apply in certain `only`
  or `without` selection on iteration, not just `first` and `last`.

* \#1874 Fixed the reject all blank proc constant to handle values
  properly with a destroy non blank value. (Stefan Daschek)

* \#1869/\#1868 Delayed atomic sets now uses the atomic path instead of
  the metadata name to fix multiple level embedding issues.
  (Chris Micacchi provided specs)

* \#1866 Post processed defaults (procs) should be applied post binding
  of the child in a relation.build.

## 2.4.7

### Resolved Issues

* Ensure reloading of embedded documents retains reference to the parent.

* \#1837 Always pass symbol options to the driver.

* \#1836 Ensure relation counts pick up persisted document that have not
  had the foreign key link persisted.

* \#1820 Destroying embedded documents in an embeds_many should also
  removed the document from the underlying _uncoped target and reindex
  the relation.

* \#1814 Don't cascade callbacks on after_initialize.

* \#1800 Invalid options for the Mongo connection are now filtered out.

* \#1785 Case equality has been fixed to handle instance checks properly.

## 2.4.6

### Resolved Issues

* \#1772 Allow skip and limit to convert strings to integers. (Jean Boussier)

* \#1767 Model#update_attributes accepts mass assignment options again.
  (Hans Hasselberg)

* \#1762 Criteria#any_of now properly handles localized fields.

* \#1758 Metadata now returns self on options for external library support.

* \#1757 Ensure serialization converts any attribute types to the type
  defined by the field.

* \#1756 Serializable hash options should pass through to embedded docs.

## 2.4.5

### Resolved Issues

* \#1751 Mongoid's logger now responds to level for Ruby logging API
  compatibility.

* \#1744/#1750 Sorting works now for localized fields in embedded documents
  using the criteria API. (Hans Hasselberg)

* \#1746 Presence validation now shows which locales were empty for
  localized fields. (Cyril Mougel)

* \#1727 Allow dot notation in embedded criteria to work on both embeds one
  and embeds many. (Lyle Underwood)

* \#1723 Initialize callbacks should cascade through children without needing
  to determine if the child is changed.

* \#1715 Serializable hashes are now consistent on inclusion of embedded
  documents per or post save.

* \#1713 Fixing === checks when comparing a class with an instance of a
  subclass.

* \#1495 Callbacks no longer get the 'super called outside of method` errors on
  busted 1.8.7 rubies.

## 2.4.4

### Resolved Issues

* \#1705 Allow changing the order of many to many foreign keys.

* \#1703 Updated at is now versioned again. (Lucas Souza)

* \#1686 Set the base metadata on unbind as well as bind for belongs to
  relations.

* \#1681 Attempt to create indexes for models without namespacing if the
  namespace does not exist for the subdirectory.

* \#1676 Allow eager loading to work as a default scope.

* \#1665/\#1672 Expand complex criteria in nested criteria selectors, like
  \#matches. (Hans Hasselberg)

* \#1668 Ensure Mongoid logger exists before calling warn. (Rémy Coutable)

* \#1661 Ensure uniqueness validation works on cloned documents.

* \#1659 Clear delayed atomic sets when resetting the same embedded relation.

* \#1656/\#1657 Don't hit database for uniqueness validation if BOTH scope
  and attribute hasn't changed. (priyaaank)

* \#1205/\#1642 When limiting fields returned from the database via
  `Criteria#only` and `Criteria#without` and then subsequently saving
  the document. Default values no longer override excluded fields.

## 2.4.3

### Resolved Issues

* \#1647 DateTime serialization when already in UTC does not convert to
  local time.

* \#1641/\#1639 Mongoid.observer.disable :all now behaves as AR does.

* \#1640 Update consumers should be tied to the name of the collection
  they persist to, not the name of the class.

* \#1637/\#1636 Scopes no longer modify parent class scopes when subclassing.
  (Hans Hasselberg)

* \#1629 $all and $in criteria on embedded many relations now properly
  handles regex searches and elements of varying length. (Douwe Maan)

* \#1623/\#1634 Default scopes no longer break Mongoid::Versioning.
  (Hans Hasselberg)

* \#1605 Fix regression of rescue responses, Rails 3.2

## 2.4.2

### Resolved Issues

* \#1628 _type field can once again be included in serialization to json
  or xml as a global option with `include_type_for_serialization`.
  (Roman Shterenzon)

* \#1627 Validating format now works properly with localized fields.
  (Douwe Maan)

* \#1617 Relation proxy methods now show up in Mongoid's list of
  prohibited fields.

* \#1615 Allow a single configuration of host and port for all spec runs,
  overridden by setting MONGOID_SPEC_HOST and MONGOID_SPEC_PORT env vars.

* \#1610 When versioning paranoid documents and max version is set, hard
  delete old versions from the embedded relation.

* \#1609 Allow connection retry during cursor iteration as well as all other
  operations.

* \#1608 Guard against no method errors when passing ids in nested attributes
  and the documents do not exist.

* \#1605 Remove deprecation warning on rescue responses, Rails 3.2

* \#1602 Preserve structure of $and and $or queries when typecasting.

* \#1600 Uniqueness validation no longer errors when provided a relation.

* \#1599 Make sure enumerable targets yield to what is in memory first when
  performing #each, not always the unloaded first.

* \#1597 Fix the ability to change the order of array fields with the same
  elements.

* \#1590 Allow proper serialization of boolean values in criteria where the
  field is nested inside an array.

## 2.4.1

### Resolved Issues

* \#1593 Arrays on embedded documents now properly atomically update when
  modified from original version.

* \#1592 Don't swallow exceptions from index generation in the create_indexes
  rake task.

* \#1589 Allow assignment of empty array to HABTM when no documents are yet
  loaded into memory.

* \#1587 When a previous value for an array field was an explicit nil, it can
  now be reset atomically with new values.

* \#1585 `Model#respond_to?` returns true now for the setter when allowing
  dynamic fields.

* \#1582 Allow nil values to be set in arrays.

* \#1580 Allow arrays to be set to nil post save, and not just empty.

* \#1579 Don't call #to_a on individual set field elements in criterion.

* \#1576 Don't hit database on uniqueness validation if the field getting
  validated has not changed.

* \#1571 Aliased fields get all the dirty attribute methods and all getters and
  setters for both the original name and the alias. (Hans Hasselberg)

* \#1568 Fallback to development environment with warning when no env configured.

* \#1565 For fields and foreign keys with non-standard Ruby or database names,
  use define_method instead of class_eval for creating the accessors and
  dirty methods.

* \#1557 Internal strategy class no longer conflicts with models.

* \#1551 Parent documents now return `true` for `Model#changed?` if only child
  (embedded) documents have changed.

* \#1547 Resetting persisted children from a parent save when new waits until post
  callbacks, mirroring update functionality.

* \#1536 Eager loading now happens when calling `first` or `last` on a
  criteria if inclusions are specified.

## 2.4.0

### New Features

* Ranges can now be passed to #where criteria to create a $gte/$lte query under the
  covers. `Person.where(dob: start_date...end_date)`

* Custom serializable fields can now override #selection to provide
  customized serialization for criteria queries.

* \#1544 Internals use `Array.wrap` instead of `to_a` now where possible.

* \#1511 Presence validation now supports localized fields. (Tiago Rafael Godinho)

* \#1506 `Model.set` will now accept false and nil values. (Marten Veldthuis)

* \#1505 `Model.delete_all/destroy_all` now take either a :conditions hash or
  the attributes directly.

* \#1504 `Model.recursively_embeds_many` now accepts a :cascade_callbacks
  option. (Pavel Pravosud)

* \#1496 Mongoid now casts strings back to symbols for symbol fields that
  get saved as strings by another application.

* \#1454, \#900 Associations now have an `after_build` callback that gets
  executed after `.build` or `build_` methods are called.
  (Jeffrey Jones, Ryan Townsend)

* \#1451 Ranges can now be any range value, not just numbers. (aupajo)

* \#1448 Localization is now used when sorting. (Hans Hasselberg)

* \#1422 Mongoid raises an error at yaml load if no environment is found.
  (Tom Stuart)

* \#1413 $not support added to criteria symbol methods. (Marc Weil)

* \#1403 Added configuration option `scope_overwrite_exception` which defaults to
  false for raising an error when defining a named scope with the same name of
  an existing method. (Christoph Grabo)

* \#1388 `model.add_to_set` now supports adding multiple values and performs an
  $addToSet with $each under the covers. (Christian Felder)

* \#1387 Added `Model#cache_key` for use in Rails caching. (Seivan Heidari)

* \#1380 Calling Model.find(id) will now properly convert to and from any type
  based on the type of the _id field.

* \#1363 Added fallbacks and default support to localized fields, and added
  ability to get and set all translations at once.

* \#1362 Aliased fields now properly typecast in criteria.

* \#1337 Array fields, including HABTM many foreign keys now have smarter dirty
  checking and no longer perform a simple $set if the array has changed. If
  items have only been added to the array, it performs a $pushAll. If items
  have only been removed, it performs a $pullAll. If both additions and
  removals have occurred it performs a $set to avoid conflicting mods.

### Resolved Issues

* Calling `Document#as_document` on a frozen document on Rubinius returns the
  attributes instead of nil.

* \#1554 Split application of default values into proc/non-procs, where
  non-procs get executed immediately during instantiation, and procs get
  executed after all other values are set.

* \#1553 Combinations of adding and removing values from an array use a $set
  on the current contents of the array, not the new values.

* \#1546 Dirty changes should be returned in a hash with indifferent access.

* \#1542 Eager loading now respects the options (ie skip, limit) provided to
  the criteria when fetch the associations.

* \#1530 Don't duplicate added values to arrays via dirty tracking if the
  array is a foreign key field.

* \#1529 Calling `unscoped` on relational associations now works properly.

* \#1524 Allow access to relations in overridden field setters by pre-setting
  foreign key default values.

* \#1523 Allow disabling of observers via `disable`. (Jonas Schneider)

* \#1522 Fixed create indexes rake task for Rails 3.2. (Gray Manley)

* \#1517 Fix Mongoid documents to properly work with RSpec's stub_model.
  (Tiago Rafael Godinho)

* \#1516 Don't duplicate relational many documents on bind.

* \#1515 Mongoid no longer attempts to serialize custom fields on complex
  criteria by default.

* \#1503 Has many relation substitution now handles any kind of mix of existing
  and new docs.

* \#1502 Nested attributes on embedded documents respects if the child is
  paranoid.

* \#1497 Use provided message on failing uniqueness validation. (Justin Etheredge)

* \#1491 Return nil when no default set on localized fields. (Tiago Rafael Godinho)

* \#1483 Sending module includes at runtime which add new fields to a parent
  document, also have the fields added to subclasses.

* \#1482 Applying new sorting options does not merge into previously
  chained criteria. (Gerad Suyderhoud)

* \#1481 Fix invalid query when accessing many-to-many relations before
  defaults are set.

* \#1480 Mongoid's internal serialized field types renamespaced to Internal in order
  to not conflict with ruby core classes in custom serializable types.

* \#1479 Don't duplicate ids on many-to-many when using create or create!

* \#1469 When extract_id returns nil, get the document out of the identity map
  by the criteria selector.

* \#1467 Defining a field named metadata now properly raises an invalid field
  error.

* \#1463 Batch insert consumers are now scoped to collection to avoid persistence
  of documents to other collections in callbacks going to the wrong place.

* \#1462 Assigning has many relations via nested attribtues `*_attributes=` does
  not autosave the relation.

* \#1461 Fixed serialization of foreign key fields in complex criteria not to
  escape the entire hash.

* \#1458 Versioning no longer skips fields that have been protected from mass
  assignment.

* \#1455, \#1456 Calling destroy on any document now temporarily marks it as
  flagged for destroy until the operation is complete. (Nader Akhnoukh)

* \#1453 `Model#to_key` should return a value when the document is destroyed.

* \#1449 New documents no longer get persisted when replaced on a has one as
  a side effect. (jasonsydes)

* \#1439 embedded? should return true when relation defined as cyclic.

* \#1433 Polymorphic nested attributes for embedded and relational 1-1 now
  update properly.

* \#1426 Frozen documents can now be cloned. (aagrawal2001)

* \#1382 Raise proper error when creating indexes via rake task if index
  definition is incorrect. (Mathieu Ravaux)

* \#1381, \#1371 The identity map now functions properly with inherited
  documents. (Paul Canavese)

* \#1370 Split concat on embedded arrays into its own method to handle the
  batch processing due to after callback run execution issues.

* \#1366 Array and hash values now get deep copied for dirty tracking.

* \#1359 Provide ability to not have default scope applied to all named
  scopes via using lambdas.

* \#1333 Fixed errors with custom types that exist in namespaces. (Peter Gumeson)

* \#1259 Default values are treated as dirty if they differ from the database
  state.

* \#1255 Ensure embedded documents respect the defined default scope.

## 2.3.4

* \#1445 Prevent duplicate documents in the loaded array on the target
  enumerable for relational associations.

* \#1442 When using create_ methods for has one relations, the appropriate
  destructive methods now get called when replacing an existing document.

* \#1431 Enumerable context should add to the loaded array post yield, so
  that methods like #any? that short circuit based on the value of the block
  dont falsely have extra documents.

* \#1418 Documents being loaded from the database for revision purposes
  no longer get placed in the identity map.

* \#1399 Allow conversion of strings to integers in foreign keys where the
  id is defined as an int.

* \#1397 Don't add default sorting criteria on first if they sort criteria
  already exists.

* \#1394 Fix exists? to work when count is greater than 1. (Nick Hoffman)

* \#1392 Return 0 on aggregation functions where field is nonexistent.

* \#1391 Uniqueness validation now works properly on embedded documents that are
  using primary key definitions.

* \#1390 When _type field is lower case class camelize before constantizing.

* \#1383 Fix cast on read for serializable fields that are subclassed.

* \#1357 Delayed atomic sets from update_attributes on embedded documents
  multiple levels deep now properly persist.

* \#1326 Ensure base document on HABTM gets its keys saved after saving a newly
  build child document.

* \#1301 Don't overwrite base metadata on embedded in relations if already set.

* \#1221 HABTM with inverse nil is allowed again on embedded documents.

* \#1208 Don't auto-persist child documents via the setter when setting from
  an embedded_in.

* \#791 Root document updates its timestamps when only embedded documents have
  changed.

## 2.3.3

### Resolved Issues

* \#1386 Lowered mongo/bson dependency to 1.3

* \#1377 Fix aggregation functions to properly handle nil or indefined values.
  (Maxime Garcia)

* \#1373 Warn if a scope overrides another scope.

* \#1372 Never persist when binding inside of a read attribute for validation.

* \#1364 Fixed reloading of documents with non bson object id ids.

* \#1360 Fixed performance of Mongoid's observer instantiation by hooking into
  Active Support's load hooks, a la AR.

* \#1358 Fixed type error on many to many synchronization when inverse_of is
  set to nil.

* \#1356 $in criteria can now be chained to non-complex criteria on the same
  key without error.

* \#1350, \#1351 Fixed errors in the string conversions of double quotes and
  tilde when paramterizing keys.

* \#1349 Mongoid documents should not blow up when including Enumerable.
  (Jonas Nicklas)

## 2.3.2

### Resolved Issues

* \#1347 Fix embedded matchers when provided a hash value that does not have a
  modifier as a key.

* \#1346 Dup default sorting criteria when calling first/last on a criteria.

* \#1343 When passing no arguments to `Criteria#all_of` return all documents.
  (Chris Leishman)

* \#1339 Ensure destroy callbacks are run on cascadable children when deleting via
  nested attributes.

* \#1324 Setting `inverse_of: nil` on a many-to-many referencing the same class
  returns nil for the inverse foreign key.

* \#1323 Allow both strings and symbols as ids in the attributes array for
  nested attributes. (Michael Wood)

* \#1312 Setting a logger on the config now accepts anything that quacks like a
  logger.

* \#1297 Don't hit the database when accessing relations if the base is new.

* \#1239 Allow appending of referenced relations in create blocks, post default set.

* \#1236 Ensure all models are loaded in rake tasks, so even in threadsafe mode
  all indexes can be created.

* \#736 Calling #reload on embedded documents now works properly.

## 2.3.1

### Resolved Issues

* \#1338 Calling #find on a scope or relation checks that the document in the
  identity map actually matches other scope parameters.

* \#1321 HABTM no longer allows duplicate entries or keys, instead of the previous
  inconsistencies.

* \#1320 Fixed errors in perf benchmark.

* \#1316 Added a separate Rake task "db:mongoid:drop" so Mongoid and AR can coexist.
  (Daniel Vartanov)

* \#1311 Fix issue with custom field serialization inheriting from hash.

* \#1310 The referenced many enumerable target no longer duplicates loaded and
  added documents when the identity map is enabled.

* \#1295 Fixed having multiple includes only execute the eager loading of the first.

* \#1287 Fixed max versions limitation with versioning.

* \#1277 attribute_will_change! properly flags the attribute even if no change occured.

* \#1063 Paranoid documents properly run destroy callbacks on soft destroy.

* \#1061 Raise `Mongoid::Errors::InvalidTime` when time serialization fails.

* \#1002 Check for legal bson ids when attempting conversion.

* \#920 Allow relations to be named target.

* \#905 Return normalized class name in metadata if string was defined with a
  prefixed ::.

* \#861 accepts_nested_attributes_for is no longer needed to set embedded documents
  via a hash or array of hashes directly.

* \#857 Fixed cascading of dependent relations when base document is paranoid.

* \#768 Fixed class_attribute definitions module wide.

* \#408 Embedded documents can now be soft deleted via `Mongoid::Paranoia`.

## 2.3.0

### New Features

* Mongoid now supports basic localized fields, storing them under the covers as a
  hash of locale => value pairs. `field :name, localize: true`

* \#1275 For applications that default safe mode to true, you can now tell a
  single operation to persist without safe mode via #unsafely:
  `person.unsafely.save`, `Person.unsafely.create`. (Matt Sanders)

* \#1256 Mongoid now can create indexes for models in Rails engines. (Caio Filipini)

* \#1228 Allow pre formatting of compsoite keys by passing a block to #key.
  (Ben Hundley)

* \#1222 Scoped mass assignment is now supported. (Andrew Shaydurov)

* \#1196 Timestamps can now be turned off on a call-by-call basis via the use
  of #timeless: `person.timeless.save`, `Person.timeless.create(:title => "Sir")`.

* \#1103 Allow developers to create their own custom complex criteria. (Ryan Ong)

* Mongoid now includes all defined fields in `serializable_hash` and `to_json`
  results even if the fields have no values to make serialized documents easier
  to use by ActiveResource clients.

* Support for MongoDB's $and operator is now available in the form of:
  `Criteria#all_of(*args)` where args is multiple hash expressions.

* \#1250, \#1058 Embedded documents now can have their callbacks fired on a parent
  save by setting `:cascade_callbacks => true` on the relation.
  (pyromanic, Paul Rosania, Jak Charlton)

### Major Changes

* Mongoid now depends on Active Model 3.1 and higher.

* Mongoid now depends on the Mongo Ruby Driver 1.4 and higher.

* Mongoid requires MongoDB 2.0.0 and higher.

### Resolved Issues

* \#1308 Fixed scoping of HABTM finds.

* \#1300 Namespaced models should handle recursive embedding properly.

* \#1299 Self referenced documents with versioning no longer fail when inverse_of
  is not defined on all relations.

* \#1296 Renamed internal building method to _building.

* \#1288, \#1289 _id and updated_at should not be part of versioned attributes.

* \#1273 Mongoid.preload_models now checks if preload configuration option is set,
  where Mongoid.load_models always loads everything. (Ryan McGeary)

* \#1244 Has one relations now adhere to default dependant behaviour.

* \#1225 Fixed delayed persistence of embedded documents via $set.

* \#1166 Don't load config in Railtie if no env variables defined. (Terence Lee)

* \#1052 `alias_attribute` now works again as expected.

* \#939 Apply default attributes when upcasting via #becomes. (Christos Pappas)

* \#932 Fixed casting of integer fields with leading zeros.

* \#948 Reset version number on clone if versions existed.

* \#763 Don't merge $in criteria arrays when chaining named scopes.

* \#730 Existing models that have relations added post persistence of originals
  can now have new relations added with no migrations.

* \#726 Embedded documents with compound keys not validate uniqueness correctly.

* \#582 Cyclic non embedded relations now validate uniqueness correctly.

* \#484 Validates uniqueness with multiple scopes of all types now work properly.

* Deleting versions created with `Mongoid::Versioning` no longer fires off
  dependent cascading on relations.

## 2.2.5

* This was a small patch release to address 2.2.x Heroku errors during asset
  compilation.

## 2.2.4

* \#1377 Fix aggregation functions to properly handle nil or indefined values.
  (Maxime Garcia)

* \#1373 Warn if a scope overrides another scope.

* \#1372 Never persist when binding inside of a read attribute for validation.

* \#1358 Fixed type error on many to many synchronization when inverse_of is
  set to nil.

* \#1356 $in criteria can now be chained to non-complex criteria on the same
  key without error.

* \#1350, \#1351 Fixed errors in the string conversions of double quotes and
  tilde when paramterizing keys.

* \#1349 Mongoid documents should not blow up when including Enumerable.
  (Jonas Nicklas)

## 2.2.3

* \#1295 Fixed having multiple includes only execute the eager loading of the first.

* \#1225 Fixed delayed persistence of embedded documents via $set.

* \#1002 Fix BSON object id conversion to check if legal first.

## 2.2.2

* This release removes the restriction of a dependency on 1.3.x of the mongo
  ruby driver. Users may now use 1.3.x through 1.4.x.

## 2.2.1

### Resolved Issues

* \#1210, \#517 Allow embedded document relation queries to use dot notation.
  (Scott Ellard)

* \#1198 Enumerable target should use criteria count if loaded has no docs.

* \#1164 Get rid of remaining no method in_memory errors.

* \#1070 Allow custom field serializers to have their own constructors.

* \#1176 Allow access to parent documents from embedded docs in after_destroy
  callbacks.

* \#1191 Context group methods (min, max, sum) no longer return NaN but instead
  return nil if field doesn't exist or have values.

* \#1193, \#1271 Always return Integers for integer fields with .000 precisions,
  not floats.

* \#1199 Fixed performance issues of hash and array field access when reading
  multiple times.

* \#1218 Fixed issues with relations referencing models with integer foreign keys.

* \#1219 Fixed various conflicting modifications issues when pushing and pulling
  from the same embedded document in a single call.

* \#1220 Metadata should not get overwritten by nil on binding.

* \#1231 Renamed Mongoid's atomic set class to Sets to avoid conflicts with Ruby's
  native Set after document inclusion.

* \#1232 Fix access to related models during before_destroy callbacks when
  cascading.

* \#1234 Fixed HABTM foreign key synchronization issues when destroying
  documents.

* \#1243 Polymorphic relations dont convert to object ids when querying if the
  ids are defined as strings.

* \#1247 Force Model.first to sort by ascending id to guarantee first document.

* \#1248 Added #unscoped to embedded many relations.

* \#1249 Destroy flags in nested attributes now actually destroy the document
  for has_many instead of just breaking the relation.

* \#1272 Don't modify configuration options in place when creating replica set
  connections.

## 2.2.0

### New Features

* Mongoid now contains eager loading in the form of `Criteria#includes(*args)`.
  This works on has_one, has_many, belongs_to associations and requires the identity map to
  be enabled in order to function. Set `identity_map_enabled: true` in your
  `mongoid.yml`. Ex: `Person.where(title: "Sir").includes(:posts, :game)`

* Relations can now take a module as a value to the `:extend` option. (Roman
  Shterenzon)

* Capped collections can be created by passing the options to the `#store_in`
  macro: `Person.store_in :people, capped: true, max: 1000000`

* Mongoid::Collection now supports `collection.find_and_modify`

* `Document#has_attribute?` now aliases to `Document#attribute_present?`

* \#930 You can now turn off the Mongoid logger via the mongoid.yml by
doing `logger: false`

* \#909 We now raise a `Mongoid::Errors::Callback` exception if persisting with
a bang method and a callback returns false, instead of the uninformative
validations error from before.

### Major Changes

* \#1173 has_many relations no longer delete all documents on a set of the relation
 (= [ doc_one, doc_two ]) but look to the dependent option to determine what
 behaviour should occur. :delete and :destroy will behave as before, :nullify and
 no option specified will both nullify the old documents without deleting.

* \#1142, \#767 Embedded relations no longer immediately persist atomically
when accessed via a parent attributes set. This includes nested attributes setting
and `attributes=` or `write_attributes`. The child changes then remain dirty and
atomically update when save is called on them or the parent document.

### Resolved Issues

* \#1190 Fixed the gemspec errors due to changing README and CHANGELOG to markdown.

* \#1180, \#1084, \#955 Mongoid now checks the field types rather than if the name
contains `/id/` when trying to convert to object ids on criteria.

* \#1176 Enumerable targets should always return the in memory documents first,
when calling `#first`

* \#1175 Make sure both sides of many to many relations are in sync during a create.

* \#1172 Referenced enumerable relations now properly handle `#to_json`
(Daniel Doubrovkine)

* \#1040 Increased performance of class load times by removing all delegate calls
to self.class.

## 2.1.9

### Resolved Issues

* \#1159 Fixed build blocks not to cancel out each other when nested.

* \#1154 Don't delete many-to-many documents on empty array set.

* \#1153 Retain parent document reference in after callbacks.

* \#1151 Fix associated validation infinite loop on self referencing documents.

* \#1150 Validates associated on `belongs_to` is `false` by default.

* \#1149 Fixed metadata setting on `belongs_to` relations.

* \#1145 Metadata inverse should return `nil` if `inverse_of` was set as `nil`.

* \#1139 Enumerable targets now quack like arrays.

* \#1136 Setting `belongs_to` parent to `nil` no longer deletes the parent.

* \#1120 Don't call `in_memory` on relations if they don't respond to it.

* \#1075 Set `self` in default procs to the document instance.

* \#1072 Writing attributes for nested documents can take a hash or array of hashes.

* \#990 Embedded documents can use a single `embedded_in` with multiple parent definitions.

## 2.1.8

### Resolved Issues

* \#1148 Fixed `respond_to?` on all relations to return properly.

* \#1146 Added back the Mongoid destructive fields check when defining fields.

* \#1141 Fixed conversions of `nil` values in criteria.

* \#1131 Verified Mongoid/Kaminari paginating correctly.

* \#1105 Fixed atomic update consumer to be scoped to class.

* \#1075 `self` in default lambdas and procs now references the document instance.

* \#740 Removed `embedded_object_id` configuration parameter.

* \#661 Fixed metadata caching on embedded documents.

* \#595 Fixed relation reload flagging.

* \#410 Moving documents from one relation to another now works as expected.

## 2.1.7

This was a specific release to fix MRI 1.8.7 breakages introduced by 2.1.6.

## 2.1.6

### Resolved Issues

* \#1126 Fix setting of relations with other relation proxies.

* \#1122 Hash and array fields now properly flag as dirty on access and change.

* \#656 Fixed reload breaking relations on unsetting of already loaded associations.

* \#647 Prefer `#unset` to `#remove_attribute` for removing values.

* \#290 Verify pushes into deeply embedded documents.

## 2.1.5

### Resolved Issues

* \#1116 Embedded children retain reference to parent in destroy callbacks.

* \#1110, \#1115 Don't memoize metadata related helpers on documents.

* \#1112 `db:create_indexes` no longer indexes subclasses multiple times.

* \#1111, \#1098 Don't set `_id` in `$set` operations.

* \#1007 Update attribute properly tracks array changes.

## 2.1.4

This was a specific release to get a Psych generated gemspec so no more parse errors would occur on those rubies that were using the new YAML parser.

## 2.1.3

### Resolved Issues

* \#1109 Fixed validations not loading one to ones into memory.

* \#1107 Mongoid no longer wants required `mongoid/railtie` in `application.rb`.

* \#1102 Fixed nested attributes deletion.

* \#1097 Reload now runs `after_initialize` callbacks.

* \#1079 Embeds many no longer duplicates documents.

* \#1078 Fixed array criteria matching on embedded documents.

* \#1028 Implement scoped on one-to-many and many-to-many relations.

* \#988 Many-to-many clear no longer deletes the child documents.

* \#977 Autosaving relations works also through nested attributes.

* \#972 Recursive embedding now handles namespacing on generated names.

* \#943 Don't override `Document#attributes`.

* \#893 Verify count is not caching on many to many relations.

* \#815 Verify `after_initialize` is run in the correct place.

* \#793 Verify `any_of` scopes chain properly with any other scope.

* \#776 Fixed mongoid case quality when dealing with subclasses.

* \#747 Fixed complex criteria using its keys to render its string value.

* \#721 `#safely` now properly raises validation errors when they occur.

## 2.1.2

### Resolved Issues

* \#1082 Alias `size` and `length` to `count` on criteria. (Adam Greene)

* \#1044 When multiple relations are defined for the same class, always return the default inverse first if `inverse_of` is not defined.

* \#710 Nested attributes accept both `id` and `_id` in hashes or arrays.

* \#1047 Ignore `nil` values passed to `embeds_man` pushes and substitution. (Derick Bailey)

## 2.1.1

### Resolved Issues

* \#1021, \#719 Many to many relations dont trigger extra database queries when pushing new documents.

* \#607 Calling `create` on large associations does not load the entire relation.

* \#1064 `Mongoid::Paranoia` should respect `unscoped` and `scoped`.

* \#1026 `model#update_attribute` now can update booleans to `false`.

* \#618 Crack XML library breaks Mongoid by adding `#attributes` method to the `String` class. (Stephen McGinty)

## 2.1.0

### Major Changes

* Mongoid now requires MongoDB 1.8.x in order to properly support the `#bit` and `#rename` atomic operations.

* Traditional slave support has been removed from Mongoid. Replica sets should be used in place of traditional master and slave setups.

* Custom field serialization has changed. Please see [serializable](https://github.com/mongoid/mongoid/blob/master/lib/mongoid/fields/serializable.rb) for changes.

* The dirty attribute tracking has been switched to use ActiveModel, this brings many bug fixes and changes:

  * \#756 After callbacks and observers see what was changed instead of changes just made being in previous_changes

  * \#434 Documents now are flagged as dirty when brand new or the state on instantiation differs from the database state. This is consistent with ActiveRecord.

  * \#323 Mongoid now supports [field]_will_change! from ActiveModel::Dirty

* Mongoid model preloading in development mode now defaults to `false`.

* `:autosave => true` on relational associations now saves on update as well as create.

* Mongoid now has an identity map for simple `find_by_id` queries. See the website for documentation.

### New Features

* \#1067 Fields now accept a `:versioned` attribute to be able to disable what fields are versioned with `Mongoid::Versioning`. (Jim Benton)

* \#587 Added order preference to many and many to many associations. (Gregory Man)

* Added ability to chain `order_by` statements. (Gregory Man)

* \#961 Allow arbitrary `Mongo::Connection` options to pass through `Mongoid::Config::Database` object. (Morgan Nelson)

* Enable `autosave` for many to many references. (Dave Krupinski)

* The following explicit atomic operations have been added: `Model#bit`, `Model#pop`, `Model#pull`, `Model#push_all`, `Model#rename`, `Model#unset`.

* Added exception translations for Hindi. (Sukeerthi Adiga)

### Resolved Issues

* \#974 Fix `attribute_present?` to work correctly then attribute value is `false`, thanks to @nickhoffman. (Gregory Man)

* \#960 create indexes rake task is not recognizing a lot of mongoid models because it has problems guessing their model names from filenames. (Tobias Schlottke)

* \#874 Deleting from a M-M reference is one-sided. (nickhoffman, davekrupinski)

* Replace deprecated `class_inheritable_hash` dropped in Rails 3.1+. (Konstantin Shabanov)

* Fix inconsistent state when replacing an entire many to many relation.

* Don't clobber inheritable attributes when adding subclass field inheritance. (Dave Krupinski)

* \#914 Querying embedded documents with `$or` selector. (Max Golovnia)

* \#514 Fix marshaling of documents with relation extensions. (Chris Griego)

* `Metadata#extension` now returns a `Module`, instead of a `Proc`, when an extension is defined.

* \#837 When `allow_dynamic_fields` is set to `false` and loading an embedded document with an unrecognized field, an exception is raised.

* \#963 Initializing array of embedded documents via hash regressed (Chris Griego, Morgan Nelson)

* `Mongoid::Config.reset` resets the options to their default values.

* `Mongoid::Fields.defaults` is memoized for faster instantiation of models.
