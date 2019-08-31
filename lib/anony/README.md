# Anony

> Anony is a small library that defines how ActiveRecord models should be anonymised for
> deletion purposes, by explicitly declaring which fields should be altered (and which
> ones should not).

## Usage

```ruby
class Employee < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    hex :first_name, opts: { max_length: 12 }
    nilable :middle_name
    ignore :id
  end
end

employee = Employee.find(1)
 => #≤Employee id="1" first_name="Alice" middle_name="in">

employee.anonymise
 => #≤Employee id="1" first_name="bf2eb0fec2ac" middle_name=nil>

employee.save!
 => true
```

Anony defines some common strategies internally, but you can also write your own - they
just need to be objects which conform to the `.call(value, opts: {})` signature:

```ruby
module OverwriteUUID
  def self.call(_value, opts: {})
    SecureRandom.uuid
  end
end

class Manager < ApplicationRecord
  include Anony::Anonymisable

  anonymise do
    with_strategy :id, OverwriteUUID
    with_strategy(:first_name) { |name, _opts| name.reverse }
  end
end

manager = Manager.first
 => #<Manager id=42>

manager.anonymise
 => #<Manager id="e9ab2800-d4b9-4227-94a7-7f81118d8a8a">

manager.save!
 => true
```

## Testing

Anony exposes an instance method called `#valid_anonymisation?` which is called before
anonymisation, but you can also run it yourself in tests to be sure that all fields have been
correctly defined. A simple spec would be:

```ruby
RSpec.describe Employee do
  subject { described_class.new }

  it { is_expected.to be_valid_anonymisation }
  specify { expect(subject.anonymise).to be_valid }
end
```
## Future ideas

* Automatically verify fields configuration when the `.anonymise` block is closed (this
  gives static confirmation that they have been set correctly, and could prevent the
  application from booting until fixed)
