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

## To generate a new view:

```
$ rails generate scenic_view searches
```

This will generate a migration file and a view definition at
`db/views/searches_v1.sql`. Open that file, write the SQL query you would like
to populate your view -- omitting the `CREATE VIEW` boilerplate -- and then run
`rake db:migrate`.

## Want to update an existing view?

```
$ rails generate scenic_view searches
```

This will generate a migration and a view definition at
`db/views/searches_v2.sql`. The file will be populated with the previous view
definition for you to edit as desired. When you're done, run `rake db:migrate`.
