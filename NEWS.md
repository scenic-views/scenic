# News

The noteworthy changes for each Scenic version are included here. For a complete
changelog, see the [CHANGELOG] for each version via the version links.

[CHANGELOG]: https://github.com/thoughtbot/scenic/commits/master

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
