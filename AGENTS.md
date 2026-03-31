# Project Description

Mongoid is a Ruby Object-Document Mapper (ODM) framework for MongoDB. Mongoid allows developers to define their data models using Ruby classes, and it handles the mapping between these classes and the underlying MongoDB collections. It is built on top of the MongoDB Ruby driver, and is intended to be a (mostly) drop-in replacement for ActiveRecord in Ruby on Rails applications.

# Project Structure

- `examples` - example scripts showing how to use Mongoid
- `gemfiles` - Gemfiles for testing different usage scenarios. `standard.gemfile` is the default, and is used for development, testing, and production.
- `lib` - the main source code for Mongoid
- `perf` - performance and benchmark scripts
- `spec` - RSpec tests for Mongoid

# Code Review Guidelines

When reviewing code, focus on:

## Security Critical Issues
- Check for hardcoded secrets, API keys, or credentials
- Check for instances of potential method call injection, dynamic code execution, symbol injection or other code injection vulnerabilities.

## Performance Red Flags
- Spot inefficient loops and algorithmic issues.
- Check for memory leaks and resource cleanup.

## Code Quality Essentials
- Methods should be focused and appropriately sized. If a method is doing too much, suggest refactorings to split it up.
- Use clear, descriptive naming conventions.
- Avoid encapsulation violations and ensure proper separation of concerns.
- All public classes, modules, and methods should have clear documentation in YARD format.
- If `method_missing` is implemented, ensure that `respond_to_missing?` is also implemented.
- Rubocop is used by this project to enforce code style. Always refer to the project's .rubocop.yml file for guidance on the project's style preferences.

## Mongoid-specific Concerns
- Mongoid::Document classes may be declared to exist in different database clusters. Look for code that should be multi-cluster-aware.
- Query state is stored on the current thread or fiber (depending on the current value of Mongoid::Config.isolation_level). Look for code that might fail in a multi-threaded or multi-fiber setup, including resources that ought to be protected by a synchronization mechanism.

## Review Style
- Be specific and actionable in feedback
- Explain the "why" behind recommendations
- Acknowledge good patterns when you see them
- Ask clarifying questions when code intent is unclear
- When possible, suggest that the pull request be labelled as a `bug`, a `feature`, or a `bcbreak` (a "backwards-compatibility break").
- PR's with no user-visible effect do not need to be labeled.

Always prioritize security vulnerabilities and performance issues that could impact users.

Always suggest changes to improve readability and testability.

Be encouraging.
