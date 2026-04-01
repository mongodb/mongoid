# Project Description

Mongoid is a Ruby Object-Document Mapper (ODM) framework for MongoDB. Mongoid allows developers to define their data models using Ruby classes, and it handles the mapping between these classes and the underlying MongoDB collections. It is built on top of the MongoDB Ruby driver, and is intended to be a (mostly) drop-in replacement for ActiveRecord in Ruby on Rails applications. The project targets Ruby 2.7+. Do not use syntax or stdlib features unavailable in Ruby 2.7.

# Project Structure

- `lib/`: the main source code for Mongoid
- `spec/`: RSpec tests for Mongoid
- `examples/`: example scripts showing how to use Mongoid
- `gemfiles/`: Gemfiles for testing different usage scenarios (`standard.gemfile` is the default, used for development, testing, and production)
- `perf/`: performance and benchmark scripts


# Development Workflow

## Running tests

Tests require a running MongoDB instance. Set the URI via the `MONGODB_URI` environment variable:

```
MONGODB_URI="mongodb://localhost:27017,localhost:27018,localhost:27019/" bundle exec rspec spec/path/to/spec.rb
```

A replica set is typically available locally at `localhost:27017,27018,27019`.

## Linting

Run RuboCop after making changes, and always before committing:

```
bundle exec rubocop lib/mongoid/changed_file.rb spec/mongoid/changed_file_spec.rb
```

Pass the specific files you modified.

RuboCop is configured with performance, rake, and rspec plugins (`.rubocop.yml`).

## Commit convention

Prefix commit messages with the JIRA ticket: `MONGOID-#### Short description`. The ticket number is typically in the branch name.

## Prose style

When writing prose — commit messages, code comments, documentation — be concise, write as a human would, avoid overly complicated sentences, and use no emojis.

## Definition of done

Always run the relevant spec file(s) against the local cluster before considering a task complete. Running tests is not optional. "Relevant" means: the spec file for each class you changed, plus any integration specs that exercise the affected feature. If MongoDB is not reachable, report this to the user rather than trying to work around it.

## Thread, fiber, and multi-cluster safety

Query state is stored on the current thread or fiber (depending on `Mongoid::Config.isolation_level`). Mongoid::Document classes may exist in different database clusters. When writing or modifying code that touches query scoping, persistence, or shared state, always consider multi-threaded, multi-fiber, and multi-cluster scenarios. Use existing synchronization primitives in the codebase rather than introducing new ones.


# Code Reviews

See [.github/code-review.md](.github/code-review.md) for code review guidelines.
