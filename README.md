# Anony

Anony is a small library that defines how ActiveRecord models should be anonymised for
deletion purposes.

```ruby
class User < ActiveRecord::Base
  include Anony::Anonymisable

  anonymise do
    overwrite do
      hex :first_name
    end
  end
end
```
```ruby
irb(main):001:0> user = User.find(1)
=> #<User id="1" first_name="Alice">

irb(main):002:0> user.anonymise!
 => #<Anony::Result status="overwritten" fields=[:first_name] error=nil>
```

For our policy on compatibility with Ruby and Rails versions, see [COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Installation & configuration

This library is distributed as a Ruby gem, and we recommend adding it your Gemfile:

```ruby
gem "anony"
```

The library injects itself using a mixin. To add this to a model class, you should include
`Anony::Anonymisable`:

```ruby
class User < ActiveRecord::Base
  include Anony::Anonymisable
  # ...
end
```

Alternatively, if you have a Rails application, you might wish to expose this behaviour
for all of your models: in which case, you can instead add it to `ApplicationRecord` once:

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  include Anony::Anonymisable
end
```

## Usage

There are two primary ways to use this library: to either overwrite existing fields on a
record, or to destroy the record altogether.

First, you should establish an `anonymise` block in your model class:

```ruby
class Employee < ActiveRecord::Base
  include Anony::Anonymisable

  anonymise do
  end
end
```

If you want to overwrite certain fields on the model, you should use the `overwrite`
DSL. There are many different ways (known as "strategies") to overwrite your fields (see
[Field strategies](#field-strategies) below). For now, let's use the `hex` & `nilable` strategies, which
overwrites fields using `SecureRandom.hex` or sets them to `nil`:

```ruby
anonymise do
  overwrite do
    hex :field_name
    nilable :nullable_field
  end
end
```

Alternative, you may wish to simply destroy the record altogether when we call
`#anonymise!` (this is useful if you're anonymising a collection of different models
together, only some of which need to be destroyed). This can be configured liked so:

```ruby
anonymise do
  destroy
end
```

Please note that both the `overwrite` and `destroy` strategies cannot be used simultaneously.

Now, given a model instance, we can use the `#anonymise!` method to apply our strategies:

```ruby
irb(main):001:0> model = Model.find(1)
=> #<Model id="1" field_name="Previous value" nullable_field="Previous">

irb(main):002:0> model.anonymise!
 => #<Anony::Result status="overwritten" fields=[:field_name, :nullable_field] error=nil>
```

 Or, if you were using the `destroy` strategy:

```ruby
irb(main):002:0> model.anonymise!
=> #<Anony::Result status="destroyed" fields=nil error=nil>
```

### Result object

When a model is anonymised, an `Anony::Result` is returned. This allows the library to detail the changes is made and the strategy it used. The result object also contains the errors that may have been raised within Anony, allowing you to handle them elegantly without using the exceptions for flow control.

The result object has 3 attributes:

  * `status` - If the model was `destroyed`, `overwritten`, `skipped` or the operation `failed`
  * `fields` - In the event the model was `overwritten`, the fields that were updated (excludes timestamps)
  * `error` - In the event the anonymisation `failed`, then the associated error. Note only rescues the following errors: `Anony::FieldException`, `ActiveRecord::RecordNotSaved`, `ActiveRecord::RecordNotDestroyed`. Anything else is thrown.

For convenience, the result object can also be queried with `destroyed?`, `overwritten?`, `skipped?` and `failed?`, so that it can be directly interrogated or used in a `switch case` with the `status` property.

### Field strategies

This library ships with a number of built-in strategies:

  * **nilable** overwrites the field with `nil`
  * **hex** overwrites the field with random hexadecimal characters
  * **email** overwrites the field with an email
  * **phone_number** overwrites the field with a dummy phone number
  * **current_datetime** overwrites the field with `Time.zone.now` (using [ActiveSupport's TimeWithZone](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-now))

### Custom strategies

You can override the default strategies, or add your own ones to make them available
everywhere, using the `Anony::FieldLevelStrategies.register(name, &block)` method somewhere after
your application boots (e.g. in a Rails initializer):

```ruby
Anony::FieldLevelStrategies.register(:reverse) do |original|
  original.reverse
end

class Employee < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    overwrite do
      reverse :first_name
    end
  end
end
```

> One strategy you might want to override is `:email`, if your application has a more
> specific replacement. For example, at GoCardless we use an email on the
> `@gocardless.com` domain so we can ensure any emails accidentally sent to this address
> would be quickly identified and fixed. `:phone_number` is another strategy that you
> might wish to replace (depending on your primary location).

You can also use strategies on a case-by-case basis, by honouring the
`.call(existing_value)` signature:

```ruby
module OverwriteUUID
  def self.call(_existing_value)
    SecureRandom.uuid
  end
end
```

```ruby
require "overwrite_uuid"

class Manager < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    overwrite do
      with_strategy OverwriteUUID, :id
    end
  end
end
```

If your strategy doesn't respond to `.call`, then it will be used as a constant value
whenever the field is anonymised.

```ruby
class Manager < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    overwrite do
      with_strategy 123, :id
    end
  end
end
```

```
irb(main):001:0> manager = Manager.first
 => #<Manager id=42>

irb(main):002:0> manager.anonymise!
 => #<Anony::Result status="overwritten" fields=[:id] error=nil>

irb(main):003:0> manager
 => #<Manager id=123>
```

You can also use a block, which is executed in the context of the model so it can
access local properties & methods. Blocks take the existing value of the column as the
only argument:

```ruby
class Manager < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    overwrite do
      with_strategy(:first_name) { |name| Digest::SHA2.hexdigest(name) }
      with_strategy(:last_name) { "previous-name-of-#{id}" }
    end
  end
end
```

```
irb(main):001:0> manager = Manager.first
 => #<Manager id=42>

irb(main):002:0> manager.anonymise!
=> #<Anony::Result status="overwritten" fields=[:first_name, :last_name] error=nil>

irb(main):003:0> manager
 => #<Manager first_name="e9ab2800-d4b9-4227-94a7-7f81118d8a8a" last_name="previous-name-of-42">
```

### Identifying anonymised records

If your model has an `anonymised_at` column, Anony will automatically set that value
when calling `#anonymise!` (similar to how Rails will modify the `updated_at` timestamp).
This means you could automatically filter out anonymised records without matching on the
anonymised values.

Here is an example of adding this column with new tables:

```ruby
class AddEmployees < ActiveRecord::Migration[6.0]
  def change
    create_table(:employees) do |t|
      # ... the rest of your columns
      t.column :anonymised_at, :datetime, null: true
    end
  end
end
```

Here is an example of adding this column to an existing table:

```ruby
class AddAnonymisedAtToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column(:employees, :anonymised_at, :datetime, null: true)
  end
end
```

Records can then be filtered out like so:

```ruby
class Employees < ApplicationRecord
  scope :without_anonymised, -> { where(anonymised_at: nil) }
end
```

### Preventing anonymisation

You might have a need to preserve model data in some (or all) circumstances. Anony exposes
the `skip_if` DSL for expressing this preference, which runs the given block before
attempting any strategy.

* If the block returns _truthy_, anonymisation is skipped.
* If the block returns _falsey_, anonymisation continues.

```ruby
class Manager
  def should_not_be_anonymised?
    id == 1 # The first manager must be kept
  end

  anonymise do
    skip_if { should_not_be_anonymised? }
  end
end
```

The result object will indicate the model was skipped:

```
irb(main):001:0> manager = Manager.find(1)
 => #<Manager id=1>

irb(main):002:0> manager.anonymise!
=> #<Anony::Result status="skipped" fields=[] error=nil>
```

## Incomplete field strategies

One of the goals of this library is to ensure that your field strategies are _complete_,
i.e. that the anonymisation behaviour of the model is always correct, even when database
columns are added/removed or the contents of those columns changes.

As such, Anony will validate your model configuration when you try to anonymise the
model (unfortunately this cannot be safely done at boot as the database might not be
available). If your configuration is incomplete, calling `#anonymise!` will fail, and a
`FieldsException` will be returned in the `error` attribute of the `Anony:Result` object.
This exception will warn which fields are missing.

```
irb(main):001:0> manager = Manager.find(1)
 => #<Manager id=1>

irb(main):002:0> manager.anonymise!
=> #<Anony::Result status="failed", fields=[], error=#<Anony::FieldException: Invalid anonymisation strategy for field(s) [:email]>>
```

We recommend adding a test for each model that you anonymise (see [Testing](#testing)
below).

### Adding new columns

Anony will fail if you try to anonymise a model without specifying a
strategy for all of the columns (to ensure that anonymisation rules aren't missed over
time). However, it's fine to define a strategy for a column
that hasn't yet been added.

This means that, in order to add a new column, you should:

  1. Define a strategy for the new column (e.g. `nilable :new_column`)
  2. Add the column in a database migration.

> At GoCardless we do zero-downtime deploys so we would deploy the first change before
> then deploying the migration.

### Excluding common Rails columns

Rails applications typically have an `id`, `created_at` and `updated_at` column on all new
tables by default. To avoid anonymising these fields (and thus prevent a
`FieldsException`), they can be globally ignored:

```ruby
# config/initializers/anony.rb

Anony::Config.ignore_fields(:id, :created_at, :updated_at)
```

By default, `Config.ignore_fields` is an empty array and all fields are considered
anonymisable.

## Testing

This library ships with a set of useful RSpec examples for your specs. Just require them
somewhere before running your spec:

```ruby
require "anony/rspec_shared_examples"
```

```ruby
# spec/models/employee_spec.rb

RSpec.describe Employee do
  # We use FactoryBot at GoCardless, but
  # however you setup a model instance is fine
  subject { FactoryBot.build(:employee) }

  # If you just anonymise fields normally
  it_behaves_like "overwritten anonymisable model"

  # Or, if your anonymised model should be skipped
  it_behaves_like "skipped anonymisable model"

  # Or, if you anonymise by destroying the record
  it_behaves_like "anonymisable model with destruction"
end
```

You can also override the subject _inside_ the shared example if it helps (e.g. if you
need to persist the record before anonymising it):

```ruby
RSpec.describe Employee do
  it_behaves_like "anonymisable model with destruction" do
    subject { FactoryBot.create(:employee) }
  end
end
```

If you're not using RSpec, or want more control over the tests, Anony also exposes an
instance method called `#valid_anonymisation?`. A simple spec would be:

```ruby
RSpec.describe Employee do
  subject { described_class.new }

  it { is_expected.to be_valid_anonymisation }
end
```

## Integration with Rubocop

At GoCardless, we use Rubocop heavily to ensure consistency in our applications. This
library includes some Rubocop cops, which can be used by adding `anony/cops` to the
`require` list in your `.rubocop.yml`:

```yml
require:
  - anony/cops
```

### `Lint/DefineDeletionStrategy`

This cop ensures that all models in your application have defined an `anonymise` block.
The output looks like this:

```
app/models/employee.rb:7:1: W: Lint/DefineDeletionStrategy:
  Define .anonymise for Employee, see https://github.com/gocardless/anony/blob/master/README.md for details:
  class Employee < ApplicationRecord ...
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

If your models do not inherit from `ApplicationRecord`, you can specify their superclass
in your `.rubocop.yml`:

```yml
Lint/DefineDeletionStrategy:
  ModelSuperclass: Acme::Record
```

## License & Contributing

* Anony is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
* Bug reports and pull requests are welcome on GitHub at https://github.com/gocardless/anony.

GoCardless ♥ open source. If you do too, come [join us](https://gocardless.com/about/jobs).
