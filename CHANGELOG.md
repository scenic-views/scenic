# Changelog

The noteworthy changes for each Scenic version are included here. For a complete
changelog, see the [commits] for each version via the version links.

[commits]: https://github.com/scenic-views/scenic/commits/master

## next

### Added

- `rename_view` allow to rename a view. Generators have been updated to
  accept a `--rename` option.

## [1.5.4] - September 16, 2020

[1.5.4]: https://github.com/scenic-views/scenic/compare/v1.5.3...v1.5.4

### Fixed

- Added missing changelog for v1.5.3.

## [1.5.3] - September 15, 2020

[1.5.3]: https://github.com/scenic-views/scenic/compare/v1.5.2...v1.5.3

### Fixed

- `scenic-oracle_enhanced_adapter` has been pulled from rubygems.
  `scenic-oracle_adapter` is a current, maintained alternative.
- Updated code snippets - since Rails 5.0, all models inherit from
  ApplicationRecord (#302)
- Update Caleb's last name

### Added

- Add Security Policy

## [1.5.2] - February 6, 2020

### Fixed

- The schema statement `create_view` is now reversible when passed a `version`
  argument.
- Calling `refresh_materialized_view` with both `concurrently` and `cascade` set
  to `true` now correctly cascades the concurrent refresh to dependent views.
- File generation and lookup now operates correctly for schema-qualified names
  like `warehouse.archived_posts`.

[1.5.2]: https://github.com/scenic-views/scenic/compare/v1.5.1...v1.5.2

## [1.5.1] - February 10, 2019

### Fixed

- Passing `no_data: true` when creating a materialized view would error if the
  corresponding SQL file had statement-terminating semicolon.

[1.5.1]: https://github.com/scenic-views/scenic/compare/v1.5.0...v1.5.1

## [1.5.0] - February 8, 2019

### Added

- `create_view` can now be passed `materialized: { no_data: true }` to create
  the materialized view without populating it. Generators have been updated to
  accept a `--no-data` option.

### Fixed

- Passing `cascade: true` when refreshing a materialized view will no longer
  error when the view in question has no dependencies.
- Fixed runtime deprecation warnings when using `pg` 0.21 and newer.
- Fixed a cascading refresh issue when the name of the view to trigger the
  refresh is a substring of one of its dependencies.


[1.5.0]: https://github.com/scenic-views/scenic/compare/v1.4.1...v1.5.0

## [1.4.1] - December 15, 2017

### Fixed

- View migrations created under Rails 5 and newer will use the current migration
  version in the generated migration class rather than always using `5.0`.

[1.4.1]: https://github.com/scenic-views/scenic/compare/v1.4.0...v1.4.1

## [1.4.0] - May 11, 2017

### Added

- `refresh_materialized_view` now accepts a `cascade` option, which defaults to
  `false`. Setting this option to `true` will refresh any materialized views the
  current view depends on first, ensuring the view being refreshed has the most
  up-to-date information.
- `sql_definition` argument is now supported when using `update_view`.

### Fixed

- View migrations created under Rails 5 and newer will no longer result in
  warnings.
- `ar_internal_metadata` is no longer included in the schema dump for Rails 5
  and newer apps.
- Using the `scenic:model` generator will no longer create a fixture or factory.

[1.4.0]: https://github.com/scenic-views/scenic/compare/v1.3.0...v1.4.0

## [1.3.0] - May 27, 2016

### Added
- Add `replace_view` migration statement, which issues `CREATE OR REPLACE
  VIEW` rather than `CREATE VIEW` or `DROP VIEW` and `CREATE VIEW`.
- Schema-qualify views outside the 'public' namespace, such as
  `scenic.searches`

### Fixed
* Singularize generated model name when injecting into class.
  Previously, pluralized names would issue a warning and Scenic would
  attempt to insert model code into the pluralized model file.
* Convert shell-based smoke tests to RSpec syntax.

[1.3.0]: https://github.com/scenic-views/scenic/compare/v1.2.0...v1.3.0

## [1.2.0] - February 5, 2016

### Added
- The generators now accept namespaced view definitions. For example: `rails
  generate scenic:view my_app.users`.

### Fixed
- Materialized view indexes are now properly dumped to `db/schema.rb`. This was
  an oversight in previous releases, meaning `rake db:schema:load` was missing
  indexes.
- Calling `update_view` for a materialized view now properly finds associated
  indexes for automatic reapplication. An issue in the previous index query was
  returning no indexes.

**Note**: Dumping materialized view indexes will produce an invalid
`db/schema.rb` file  under Rails 5 beta 1 and beta 2. This is fixed on Rails
master.

[1.2.0]: https://github.com/scenic-views/scenic/compare/v1.1.1...v1.2.0

## [1.1.1] - January 29, 2016

### Fixed
- Some schema operations were failing with a `PG::ConnectionBad: connection is
  closed` error. This has been fixed by ensuring we grab a fresh connection for
  all operations.

[1.1.1]: https://github.com/scenic-views/scenic/compare/v1.1.0...v1.1.1

## [1.1.0] - January 8, 2016

### Added
- Added support for updating materialized view definitions while maintaining
  existing indexes that are still applicable after the update.
- Added support for refreshing materialized views concurrently (requires
  Postgres 9.4 or newer).

### Fixed
- The schema dumper will now dump views and materialized views together in the
  order they are returned by Postgres. This fixes issues when loading views that
  depend on other views via `rake db:schema:load`.
- Scenic now works on [supported versions of Postgres] older than 9.3.0.
  Attempts to use database features not supported by your specific version of
  Postgres will raise descriptive errors.
- Fixed inability to dump materialized views in Rails 5.0.0.beta1.

[supported versions of Postgres]: http://www.postgresql.org/support/versioning/
[1.1.0]: https://github.com/scenic-views/scenic/compare/v1.0.0...v1.1.0

## [1.0.0] - November 23, 2015

### Added
- Added support for [materialized views].
- Allow changing the database adapter via `Scenic::Configuration`.

### Fixed
- Improved formatting of the view when dumped to `schema.rb`.
- Fixed generation of namespaced models by using ActiveRecord's own model
  generator.
- Eliminated `alias_method_chain` deprecation when running with Rails master
  (5.0).

[materialized views]:https://github.com/scenic-views/scenic/blob/v1.0.0/README.md
[1.0.0]: https://github.com/scenic-views/scenic/compare/v0.3.0...v1.0.0

## [0.3.0] - January 23, 2015

### Added
- Previous view definition is copied into new view definition file when updating
  an existing view.

### Fixed
- We avoid dumping views that belong to Postgres extensions.
- `db/schema.rb` is prettier thanks to a blank line after each view definition.

[0.3.0]: https://github.com/scenic-views/scenic/compare/v0.2.1...v0.3.0

## [0.2.1] - January 5, 2015

### Fixed
- View generator will now create `db/views` directory if necessary.

[0.2.1]: https://github.com/scenic-views/scenic/compare/v0.2.0...v0.2.1

## [0.2.0] - August 11, 2014

### Added
- Teach view generator to update existing views.

### Fixed
- Raise an error if view definition is empty.

[0.2.0]: https://github.com/scenic-views/scenic/compare/v0.1.0...v0.2.0

## [0.1.0] - August 4, 2014

Scenic makes it easier to work with Postgres views in Rails.

It introduces view methods to ActiveRecord::Migration and allows views to be
dumped to db/schema.rb.  It provides generators for models, view definitions,
and migrations.  It is built around a basic versioning system for view
definition files.

In short, go add a view to your app.

[0.1.0]: https://github.com/scenic-views/scenic/compare/8599daa132880cd6c07efb0395c0fb023b171f47...v0.1.0
