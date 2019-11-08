# Anony

> Anony is a small library that defines how ActiveRecord models should be anonymised for
> deletion purposes.

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

It's possible to ignore some common columns using configuration. For example, in Rails
applications, the `id`, `created_at` and `updated_at` fields are unlikely to be
anonymisable. When the configuration is validated, Anony won't throw an error for those
columns to be ignored. If you try and ignore one of these columns, it will throw an error,
but you are still free to define another anonymisation strategy for them.

In an initializer (or at application boot outside Rails), you can set these ignorable
fields like so:

```ruby
# config/initializers/anony.rb

Anony::Config.ignore_fields(:id, :created_at, :updated_at)
```

There are some models which should be destroyed as part of anonymisation.  This can be done using the `destroy` method:

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
## Future ideas

* Automatically verify fields configuration when the `.anonymise` block is closed (this
  gives static confirmation that they have been set correctly, and could prevent the
  application from booting until fixed)
