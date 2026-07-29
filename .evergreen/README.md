# Evergreen configuration

This directory contains configuration and scripts used to run Mongoid's test
suite in Evergreen, MongoDB's continuous integration system.

`config.yml` is generated. Do not edit it by hand. Edit the ERB templates under
`config/` and regenerate with:

```
ruby .evergreen/update-evergreen-configs
```


## Scheduled upcoming-version builds (MONGOID-5908)

Two build variants run the test suite against the upcoming, in-development
versions of Ruby and Rails, so that incompatibilities are caught before those
versions ship:

- `ruby-dev` — the main test suite against `ruby-dev` (provided by
  `mongo-ruby-toolchain`).
- `rails-master` — the main test suite against Rails `master`.

Both are defined in `config/variants.yml.erb`. Two properties matter:

- They are not tagged `pr`, so they never run on pull requests. They only run
  on the `master` waterfall.
- Their `test` task carries `batchtime: 20160` (14 days), so Evergreen
  activates each at most once every two weeks instead of on every commit.

### Failure notification

Failures of these scheduled runs should open a Jira issue in the `MONGOID`
project. This is not expressed in `config.yml`; it is an Evergreen project
notification, configured once by a project admin in the Evergreen UI:

1. Open the `mongoid` project in Evergreen, go to
   **Settings -> Notifications** (project subscriptions).
2. Add a subscription:
   - **Event**: a task finishes -> the task fails.
   - **Scope**: limit to the build variants, using a regex that matches the
     `ruby-dev` and `rails-master` variant display names (they contain
     `ruby-dev` and `Rails master`).
   - **Action**: Create a Jira issue.
   - **Project**: `MONGOID`; pick an appropriate issue type (e.g. `Task`/`Bug`).
3. Evergreen fills the issue with the failing task, the build variant (which
   names the Ruby or Rails version), the version/commit, and links to the
   failed tasks, so the report includes the version, commit hash, and the list
   of failures.

Because this lives in project settings rather than the repository, it must be
recreated if the project is reconfigured.
