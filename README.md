# Scenic

![Scenic Landscape](https://user-images.githubusercontent.com/152152/49344534-a8817480-f646-11e8-8431-3d95d349c070.png)

[![Build Status](https://github.com/scenic-views/scenic/workflows/CI/badge.svg)](https://github.com/scenic-views/scenic/actions?query=workflow%3ACI+branch%3Amaster)
[![Documentation Quality](http://inch-ci.org/github/scenic-views/scenic.svg?branch=master)](http://inch-ci.org/github/scenic-views/scenic)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

Scenic adds methods to `ActiveRecord::Migration` to create and manage database
views in Rails.

Using Scenic, you can bring the power of SQL views to your Rails application
without having to switch your schema format to SQL. Scenic provides a convention
for versioning views that keeps your migration history consistent and reversible
and avoids having to duplicate SQL strings across migrations. As an added bonus,
you define the structure of your view in a SQL file, meaning you get full SQL
syntax highlighting in the editor of your choice and can easily test your SQL in
the database console during development.

Scenic ships with support for PostgreSQL. The adapter is configurable (see
`Scenic::Configuration`) and has a minimal interface (see
`Scenic::Adapters::Postgres`) that other gems can provide.

## So how do I install this?

If you're using Postgres, Add `gem "scenic"` to your Gemfile and run `bundle
install`. If you're using something other than Postgres, check out the available
[third party adapters](https://github.com/scenic-views/scenic#faqs).

## Great, how do I create a view?

You've got this great idea for a view you'd like to call `search_results`. You
can create the migration and the corresponding view definition file with the
following command:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v01.sql
      create  db/migrate/[TIMESTAMP]_create_search_results.rb
```

Edit the `db/views/search_results_v01.sql` file with the SQL statement that
defines your view. In our example, this might look something like this:

```sql
SELECT
  statuses.id AS searchable_id,
  'Status' AS searchable_type,
  comments.body AS term
FROM statuses
JOIN comments ON statuses.id = comments.status_id

UNION

SELECT
  statuses.id AS searchable_id,
  'Status' AS searchable_type,
  statuses.body AS term
FROM statuses
```

The generated migration will contain a `create_view` statement. Run the
migration, and [baby, you got a view going][carl]. The migration is reversible
and the schema will be dumped into your `schema.rb` file.

[carl]: https://www.youtube.com/watch?v=Sr2PlqXw03Y

```sh
$ rake db:migrate
```

## Cool, but what if I need to change that view?

Here's where Scenic really shines. Run that same view generator once more:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v02.sql
      create  db/migrate/[TIMESTAMP]_update_search_results_to_version_2.rb
```

Scenic detected that we already had an existing `search_results` view at version
1, created a copy of that definition as version 2, and created a migration to
update to the version 2 schema. All that's left for you to do is tweak the
schema in the new definition and run the `update_view` migration.

## What if I want to change a view without dropping it?

The `update_view` statement used by default will drop your view then create
a new version of it.

This is not desirable when you have complicated hierarchies of views, especially
when some of those views may be materialized and take a long time to recreate.

You can use `replace_view` to generate a CREATE OR REPLACE VIEW SQL statement.

See Postgres documentation on how this works:
http://www.postgresql.org/docs/current/static/sql-createview.html

To start replacing a view run the generator like for a regular change:

```sh
$ rails generate scenic:view search_results
      create  db/views/search_results_v02.sql
      create  db/migrate/[TIMESTAMP]_update_search_results_to_version_2.rb
```

Now, edit the migration. It should look something like:

```ruby
class UpdateSearchResultsToVersion2 < ActiveRecord::Migration
  def change
    update_view :search_results, version: 2, revert_to_version: 1
  end
end
```

Update it to use replace view:

```ruby
class UpdateSearchResultsToVersion2 < ActiveRecord::Migration
  def change
    replace_view :search_results, version: 2, revert_to_version: 1
  end
end
```

Now you can run the migration like normal.

## Can I use this view to back a model?

You bet! Using view-backed models can help promote concepts hidden in your
relational data to first-class domain objects and can clean up complex
ActiveRecord or ARel queries. As far as ActiveRecord is concerned, a view is
no different than a table.

```ruby
class SearchResult < ApplicationRecord
  belongs_to :searchable, polymorphic: true

  # this isn't strictly necessary, but it will prevent
  # rails from calling save, which would fail anyway.
  def readonly?
    true
  end
end
```

Scenic even provides a `scenic:model` generator that is a superset of
`scenic:view`.  It will act identically to the Rails `model` generator except
that it will create a Scenic view migration rather than a table migration.

There is no special base class or mixin needed. If desired, any code the model
generator adds can be removed without worry.

```sh
$ rails generate scenic:model recent_status
      invoke  active_record
      create    app/models/recent_status.rb
      invoke    test_unit
      create      test/models/recent_status_test.rb
      create      test/fixtures/recent_statuses.yml
      create  db/views/recent_statuses_v01.sql
      create  db/migrate/20151112015036_create_recent_statuses.rb
```

## What about materialized views?

Materialized views are essentially SQL queries whose results can be cached to a
table, indexed, and periodically refreshed when desired. Does Scenic support
those? Of course!

The `scenic:view` and `scenic:model` generators accept a `--materialized`
option for this purpose. When used with the model generator, your model will
have the following method defined as a convenience to aid in scheduling
refreshes:

```ruby
def self.refresh
  Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
end
```

This will perform a non-concurrent refresh, locking the view for selects until
the refresh is complete. You can avoid locking the view by passing
`concurrently: true` but this requires both PostgreSQL 9.4 and your view to have
at least one unique index that covers all rows. You can add or update indexes for
materialized views using table migration methods (e.g. `add_index table_name`)
and these will be automatically re-applied when views are updated.

The `cascade` option is to refresh materialized views that depend on other
materialized views. For example, say you have materialized view A, which selects
data from materialized view B. To get the most up to date information in view A
you would need to refresh view B first, then right after refresh view A. If you
would like this cascading refresh of materialized views, set `cascade: true`
when you refresh your materialized view.

## I made a mistake and I need to rename a view?

Run the view generator as following:

```sh
$ rails generate scenic:view results --rename search_results
      create  db/views/results_v01.sql
      create  db/migrate/[TIMESTAMP]_update_results_to_version_2.rb
```

Now, `db/views/results_v01.sql` sould be identical to 
`db/views/search_results_v01.sql`, you will need to edit this file if you rename
another views in this migration that is in this definition, so just rename it
too accordingly ;-)
The migration should look something like this:

```ruby
class UpdateResultsToVersion2 < ActiveRecord::Migration
  def change
    rename_view :search_results, :results,
      version: 2,
      revert_to_version: 1
  end
end
```

## Need to change a materialized view without downtime?

Before using `replace_view` on materialized views, you need to create and
populate the next version of the view in a previous release. So you will have
to follow these steps:

1. Create a new materialized view
   `rails generate scenic:view table_name_next --materialized --no-data`
   that will take improvement of your future view `table_name`, you can 
   copy-paste the content of the last version of `table_name` as a starter.
2. Deploy and apply this migration
3. Refresh the view within a task or in the Rails console
   `Scenic.database.refresh_materialized_view(:table_name_nexts, concurrently: false)`
4. Use that view by removing the previous and renaming the next one in a single
   migration 
   `rails generate scenic:view table_name --materialized --rename table_name_next`
   and edit the migration to change `rename_view` by `replace_view`:
   ```ruby
   def change
     replace_view :table_name_nexts, :table_names,
       version: 1,
       revert_to_version: 1,
       materialized: true
   end
   ```

`replace_view` will internaly do:
1. store indexes of `table_names`
2. remove `table_names`
3. rename `table_names_next` to `table_names`
4. ensure that the definition on the database is the same as the one in 
   `db/views` folder
5. rename indexes by replacing `table_names_next` by `table_names` in 
   their names
6. applied valid stored indexes on the new version of `table_names`

## I don't need this view anymore. Make it go away.

Scenic gives you `drop_view` too:

```ruby
def change
  drop_view :search_results, revert_to_version: 2
  drop_view :materialized_admin_reports, revert_to_version: 3, materialized: true
end
```

## FAQs

**Why do I get an error when querying a view-backed model with `find`, `last`, or `first`?**

ActiveRecord's `find` method expects to query based on your model's primary key,
but views do not have primary keys. Additionally, the `first` and `last` methods
will produce queries that attempt to sort based on the primary key.

You can get around these issues by setting the primary key column on your Rails
model like so:

```ruby
class People < ApplicationRecord
  self.primary_key = :my_unique_identifier_field
end
```

**Why is my view missing columns from the underlying table?**

Did you create the view with `SELECT [table_name].*`? Most (possibly all)
relational databases freeze the view definition at the time of creation. New
columns will not be available in the view until the definition is updated once
again. This can be accomplished by "updating" the view to its current definition
to bake in the new meaning of `*`.

```ruby
add_column :posts, :title, :string
update_view :posts_with_aggregate_data, version: 2, revert_to_version: 2
```

**When will you support MySQL, SQLite, or other databases?**

We have no plans to add first-party adapters for other relational databases at
this time because we (the maintainers) do not currently have a use for them.
It's our experience that maintaining a library effectively requires regular use
of its features. We're not in a good position to support MySQL, SQLite or other
database users.

Scenic *does* support configuring different database adapters and should be
extendable with adapter libraries. If you implement such an adapter, we're happy
to review and link to it. We're also happy to make changes that would better
accommodate adapter gems.

We are aware of the following existing adapter libraries for Scenic which may
meet your needs:

* [scenic_sqlite_adapter](https://github.com/pdebelak/scenic_sqlite_adapter)
* [scenic-mysql_adapter](https://github.com/EmpaticoOrg/scenic-mysql_adapter)
* [scenic-sqlserver-adapter](https://github.com/ClickMechanic/scenic_sqlserver_adapter)
* [scenic-oracle_adapter](https://github.com/cdinger/scenic-oracle_adapter)

Please note that the maintainers of Scenic make no assertions about the
quality or security of the above adapters.

## About

Scenic is maintained by [Derek Prior], [Caleb Hearth], and you, our
contributors.

[Derek Prior]: http://prioritized.net
[Caleb Hearth]: http://calebhearth.com
