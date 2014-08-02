# Scenic

![Boston cityscape - it's scenic](http://www.california-tour.com/blog/wp-content/uploads/2011/11/skyline-boats-shutterstock-superreduced.jpg)

## Description

Scenic adds methods to ActiveRecord::Migration to create and manage database
views in Rails.

Using Scenic, you can use the power of SQL views in your Rails application
without having to switch your schema format to SQL. Scenic also handles
versioning your views in a way that eliminates duplication across migrations. As
an added bonus, you define the structure of your view in a SQL file, meaning you
get full SQL syntax highlighting support in the editor of your choice.

## Great, how do I create a view?

You've got this great idea for a view you'd like to call `searches`. Create a
definition file at `db/views/searches_v1.sql` which contains the query you'd
like to build your view with. Perhaps that looks something like this:

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

Generate a new migration with the following `change` method:

```ruby
def change
  create_view :searches
end
```

Run that migration and congrats, you've got yourself a view. The migration is
reversible and it will be dumped into your `schema.rb` file.

## Cool, but what if I need to change that view?

Add the new query to `db/views/searches_v2.sql` and generate a new migration with
the following `change` method:

```ruby
def change
  update_view :searches, version: 2, revert_to_version: 1
end
```

When you run that migration, your view will be updated. The `revert_to_version`
option makes that migration reversible.

## Can I use this view to back a model?

You bet!

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

## I don't need this view anymore. Make it go away.

We give you `drop_view` too:

```ruby
def change
  drop_view :searches, revert_to_version: 2
end
```

## Can you make this easier?

Yeah, we're working on it. We're going to provide some generators that will take
some of the busy work of file creation away. We'll create the SQL file, the
migration, and optionally the model for you.

Check out the issue tracker for our other plans.
