# Anony

> Anony is a small library that defines how ActiveRecord models should be anonymised for
> deletion purposes.

## Installation & configuration

This library is distributed as a Ruby gem, and we recommend adding it your Gemfile:

```ruby
gem "anony"
```

If you have a Rails application, you might wish to get anonymisable behaviour for all
models:

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  include Anony::Anonymisable
  # ...
end
```

Alternatively, you can just mix it into models as needed:

```ruby
class User < ApplicationRecord
  include Anony::Anonymisable
  ...
end
```

## Usage

The main idea is that you define which fields on a model should be anonymised and,
crucially, which ones should not. This means that when you're adding a new column to an
anonymisable model, you will be reminded that you need to define the anonymisation
strategy for that column.

```ruby
class Employee < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    hex :first_name, max_length: 12
    nilable :middle_name
    ignore :id
  end
end

employee = Employee.find(1)
 => #≤Employee id="1" first_name="Alice" middle_name="in">

employee.anonymise!
 => true

employee
 => #≤Employee id="1" first_name="bf2eb0fec2ac" middle_name=nil>
```

Anony defines some common strategies internally, but you can also write your own - they
just need to be objects which conform to the `.call(existing_value)` signature:

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
    with_strategy OverwriteUUID, :id
    with_strategy(:first_name) { |name| Digest::SHA2.hexdigest(name) }
  end
end

manager = Manager.first
 => #<Manager id=42>

manager.anonymise!
 => true

manager
 => #<Manager id="e9ab2800-d4b9-4227-94a7-7f81118d8a8a">
```

There are some models which should be destroyed as part of anonymisation. This can be done
using the `destroy` method:

```ruby
class Temporary < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    destroy
  end
end

temporary = Temporary.first
 => #<Temporary id=42>

temporary.anonymise!
 => true

temporary.persisted?
 => false
```

## Configuration

Anony exposes several configuration options on the `Anony::Config` singleton. We
recommend making these changes in an initializer if needed:

```ruby
# config/initializers/anony.rb

Anony::Config.ignore_fields(:id, :created_at, :updated_at)
Anony::Config.email_template = "nobody@example.net"
Anony::Config.phone_number = "+44 7700 123 456"
```

### `.ignore_fields`

Globally permit common column names (for example, `id`, `created_at` and `updated_at` in
Rails applications often appear by default in all models). By default, there are no
columns in this list (`[]`).

### `.email_template`

Configure the replacement email (by default, it will be `"#{random}@example.com"`).

### `.phone_number`

Configure the replacement phone (by default, it will be `"+1 617 555 1294"`).



## Testing

Anony exposes an instance method called `#valid_anonymisation?` which is called before
anonymisation, but you can also run it yourself in tests to be sure that all fields have been
correctly defined. A simple spec would be:

```ruby
RSpec.describe Employee do
  subject { described_class.new }

  it { is_expected.to be_valid_anonymisation }
  specify { expect(subject.anonymise!).to eq(true) }
end
```

## Integration with Rubocop

This library includes some Rubocops to ensure consistency in your codebase. Just add the
following to the `require` list in your `.rubocop.yml`:

```yml
require:
  - anony/cops
```

You can also require the individual cops if needed, e.g. with
`anony/cops/define_deletion_strategy`.

### `Lint/DefineDeletionStrategy`

This cop ensures that all models in your application have defined anonymisation
rules. The output looks like this:

```
app/models/employee.rb:7:1: W: Lint/DefineDeletionStrategy: Define .anonymise for Employee, see https://github.com/gocardless/anony/blob/v0.1/README.md for details:
class Employee < ApplicationRecord ...
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## License & Contributing

* Anony is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
* Bug reports and pull requests are welcome on GitHub at https://github.com/gocardless/anony.

GoCardless ♥ open source. If you do too, come [join us](https://gocardless.com/about/jobs).