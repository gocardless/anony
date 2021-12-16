# v1.1.0

- Drop ruby 2.4 and 2.5 support
- Unpin ActiveSupport for Rails 7

# v1.0.2

- Unpin ActiveSupport for Rails 6

# v1.0.1

* Throw a more useful exception when calling .anonymise without config [#53](https://github.com/gocardless/anony/pull/53)

# v1.0.0

* Create a result object when calling `anonymise!` [#44](https://github.com/gocardless/anony/pull/44)

# v0.8.0

* Improve the documentation [#45](https://github.com/gocardless/anony/pull/45)
* Rename fields strategy to overwrite [#46](https://github.com/gocardless/anony/pull/46)

# v0.7.3

* Allow customising the model superclass for the `DefineDeletionStrategy` cop [#36](https://github.com/gocardless/anony/pull/36)

# v0.7.2

* Add ability to prevent anonymisation with `skip_if` [#25](https://github.com/gocardless/anony/pull/25)

# v0.7.1

* Fix breakage when applying a strategy multiple times [#35](https://github.com/gocardless/anony/pull/35)

# v0.7.0

* **BREAKING** Switch to nesting field-level configuration in a `fields` block
  [#32](https://github.com/gocardless/anony/pull/32). This should just be a case of
  switching `anonymise { ... }` to `anonymise { fields { ... } }` in most cases, but for
  more details please check the README.
* **BREAKING** `Anony::Strategies.register` was renamed to `Anony::FieldLevelStrategies.register`.

# v0.6.0

* Use ActiveRecord::Persistence#current_time_from_proper_timezone [#34](https://github.com/gocardless/anony/pull/34)

# v0.5.0

* Make `valid_anonymisation?` a class method [#24](https://github.com/gocardless/anony/pull/24)
* Allow dynamic registration of Anony::Strategies [#23](https://github.com/gocardless/anony/pull/23)
* Only apply anonymisation strategies to columns that are defined [#28](https://github.com/gocardless/anony/pull/28)

# v0.4.0

* Allow using a constant value as a strategy [#19](https://github.com/gocardless/anony/pull/19)

# v0.3.1

* Fix `anonymised_at` column [#13](https://github.com/gocardless/anony/pull/13)

# v0.3.0

* Support `anonymised_at` column [#9](https://github.com/gocardless/anony/pull/9)

# v0.2.1

* Fix relative require in DefineDeletionStrategy cop [#8](https://github.com/gocardless/anony/pull/8)

# v0.2

* Improve the README [#5](https://github.com/gocardless/anony/pulls/5)
* Use Rubocop for testing code style [#6](https://github.com/gocardless/anony/pulls/6)
* Add an [RSpec helper](https://github.com/gocardless/anony/blob/v0.2/README.md#testing) for testing [#7](https://github.com/gocardless/anony/pulls/7)

# v0.1

Initial release.
