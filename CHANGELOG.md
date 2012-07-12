# Overview

For instructions on upgrading to newer versions, visit
[mongoid.org](http://mongoid.org/docs/upgrading.html).

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

* \#1976 Don't execute eager load queries when base query is empty.

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

* \#1778 Ensure foreign keys are always set regardless of binding state.

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

* \#1665/#1672 Expand complex criteria in nested criteria selectors, like
  #matches. (Hans Hasselberg)

* \#1668 Ensure Mongoid logger exists before calling warn. (Rémy Coutable)

* \#1661 Ensure uniqueness validation works on cloned documents.

* \#1659 Clear delayed atomic sets when resetting the same embedded relation.

* \#1656/#1657 Don't hit database for uniqueness validation if BOTH scope
  and attribute hasn't changed. (priyaaank)

* \#1205/#1642 When limiting fields returned from the database via
  `Criteria#only` and `Criteria#without` and then subsequently saving
  the document. Default values no longer override excluded fields.

## 2.4.3

### Resolved Issues

* \#1647 DateTime serialization when already in UTC does not convert to
  local time.

* \#1640 Update consumers should be tied to the name of the collection
  they persist to, not the name of the class.

* \#1636 Scopes no longer modify parent class scopes when subclassing.
  (Hans Hasselberg)

* \#1629 $all and $in criteria on embedded many relations now properly
  handles regex searches and elements of varying length. (Douwe Maan)

* \#1623 Default scopes no longer break Mongoid::Versioning.
  (Hans Hasselberg)

* \#1605 Fix regression of rescue responses, Rails 3.2

## 2.4.2

### Resolved Issues

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

* \#1392 Return 0 on aggregation functions where field is nonexistant.

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
