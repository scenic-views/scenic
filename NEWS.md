# News

The noteworthy changes for each Scenic version are included here. For a complete
changelog, see the [CHANGELOG] for each version via the version links.

[CHANGELOG]: https://github.com/thoughtbot/scenic/commits/master

## [1.3.0] - May 27, 2016

### Added

- An update_view migration statement (and associated code) that uses
`CREATE OR REPLACE VIEW` instead of dropping and creating the view.

### Fixed

- Issue with inconsistent singularization with materialization
  (https://github.com/thoughtbot/scenic/issues/148)
- Add view namespaces to SchemaDumper, useful when views live in another 
  schema than `public`.

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

[1.2.0]: https://github.com/thoughtbot/scenic/compare/v1.1.1...v1.2.0

## [1.1.1] - January 29, 2016

### Fixed
- Some schema operations were failing with a `PG::ConnectionBad: connection is
  closed` error. This has been fixed by ensuring we grab a fresh connection for
  all operations.

[1.1.1]: https://github.com/thoughtbot/scenic/compare/v1.1.0...v1.1.1

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
[1.1.0]: https://github.com/thoughtbot/scenic/compare/v1.0.0...v1.1.0

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

[materialized views]:https://github.com/thoughtbot/scenic/blob/v1.0.0/README.md
[1.0.0]: https://github.com/thoughtbot/scenic/compare/v0.3.0...v1.0.0

## [0.3.0] - January 23, 2015

### Added
- Previous view definition is copied into new view definition file when updating
  an existing view.

### Fixed
- We avoid dumping views that belong to Postgres extensions.
- `db/schema.rb` is prettier thanks to a blank line after each view definition.

[0.3.0]: https://github.com/thoughtbot/scenic/compare/v0.2.1...v0.3.0

## [0.2.1] - January 5, 2015

### Fixed
- View generator will now create `db/views` directory if necessary.

[0.2.1]: https://github.com/thoughtbot/scenic/compare/v0.2.0...v0.2.1

## [0.2.0] - August 11, 2014

### Added
- Teach view generator to update existing views.

### Fixed
- Raise an error if view definition is empty.

[0.2.0]: https://github.com/thoughtbot/scenic/compare/v0.1.0...v0.2.0

## [0.1.0] - August 4, 2014

Scenic makes it easier to work with Postgres views in Rails.

It introduces view methods to ActiveRecord::Migration and allows views to be
dumped to db/schema.rb.  It provides generators for models, view definitions,
and migrations.  It is built around a basic versioning system for view
definition files.

In short, go add a view to your app.

[0.1.0]: https://github.com/thoughtbot/scenic/compare/8599daa132880cd6c07efb0395c0fb023b171f47...v0.1.0
