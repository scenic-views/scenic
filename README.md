# Scenic

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

## Great, how do I create a view?

You've got this great idea for a view you'd like to call `searches`. You can
create the migration and the corresponding view definition file with the
following command:

```sh
$ rails generate scenic:view searches
      create  db/views/searches_v01.sql
      create  db/migrate/[TIMESTAMP]_create_searches.rb
```

Edit the `db/views/searches_v01.sql` file with the SQL statement that defines
your view. In our example, this might look something like this:

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
$ rails generate scenic:view searches
      create  db/views/searches_v02.sql
      create  db/migrate/[TIMESTAMP]_update_searches_to_version_2.rb
```

Scenic detected that we already had an existing `searches` view at version 1,
created a copy of that definition as version 2, and created a migration to
update to the version 2 schema. All that's left for you to do is tweak the
schema in the new definition and run the `update_view` migration.

## Can I use this view to back a model?

You bet! Using view-backed models can help promote concepts hidden in your
relational data to first-class domain objects and can clean up complex
ActiveRecord or ARel queries. As far as ActiveRecord is concerned, you a view is
no different than a table.

```ruby
class Search < ActiveRecord::Base
  private

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

### When I query that model with `find` I get an error. What gives?

Your view cannot have a primary key, but ActiveRecord's `find` method expects to
query based on one. You can use `find_by!` or you can explicitly set the primary
key column on your model like so:

```ruby
class People < ActiveRecord::Base
  self.primary_key = :id
end
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
  Scenic.database.refresh_materialized_view(table_name)
end
```

## I don't need this view anymore. Make it go away.

Scenic gives you `drop_view` too:

```ruby
def change
  drop_view :searches, revert_to_version: 2
end
```

## About

Scenic is maintained by [Derek Prior] and [Caleb Thompson], funded by
thoughtbot, inc. The names and logos for thoughtbot are trademarks of
thoughtbot, inc.

[Derek Prior]: http://prioritized.net
[Caleb Thompson]: http://calebthompson.io

![thoughtbot](https://thoughtbot.com/logo.png)

We love open source software!  See [our other projects][community] or [hire
us][hire] to help build your product.

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
