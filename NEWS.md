New in 0.3.0 (January 23, 2015)
* Previous view definition is copied into new view definition file when updating
  an existing view.
* We avoid dumping views that belong to Postgres extensions
* `db/schema.rb` is prettier thanks to a blank line after each view definition.

New in 0.2.1
* View generator will now create `db/views` directory if necessary

New in 0.2.0
* Teach view generator to update existing views [683361d](https://github.com/thoughtbot/scenic/commit/683361d59410f46aba508a3ceb850161dd0be027)
* Raise an error if view definition is empty. [PR #38](https://github.com/thoughtbot/scenic/issues/38)
