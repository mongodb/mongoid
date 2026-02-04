# Mongoization

"Mongoization" is the process of converting Ruby objects into a format suitable for storage in MongoDB. This process ensures that data types are correctly transformed to match MongoDB's expectations, allowing for seamless storage and retrieval.

This exploration assumes the following setup:

```ruby
class Person
  include Mongoid::Document

  field :birthdate, type: Date
end

person = Person.create(birthdate: '1985-10-26')
```

The birthdate gets mongoized from a String to a Date during the assignment process. The following sequence diagram illustrates the detailed steps involved in this mongoization process when creating a new document.

```mermaid
sequenceDiagram
    participant Script
    participant Lifecycle
    Script->>Document.create: Document.create(field: '1984-10-26')
    Document.create->>Lifecycle: _creating
    activate Lifecycle
    create participant DocumentNew as Document#35;new
    Document.create->>DocumentNew: new(attributes)
    create participant DocumentConstruct as Document#35;construct_document
    DocumentNew->>DocumentConstruct: construct_document(attributes)
    DocumentConstruct->>Lifecycle: _building
    activate Lifecycle
    create participant DocumentProcess1 as Document#35;process_attributes
    DocumentConstruct->>DocumentProcess1: process_attributes(attributes)
    create participant DocumentProcess2 as Document#35;process_attribute
    DocumentProcess1->>DocumentProcess2: process_attribute(key, value)
    create participant FieldAssign as Document#35;field=
    DocumentProcess2->>FieldAssign: self.field = '1984-10-26'
    create participant WriteAttr as Document#35;write_attribute
    FieldAssign->>WriteAttr: write_attribute(name, value)
    WriteAttr->>Lifecycle: _assigning
    activate Lifecycle
    create participant TypedValue as Document#35;typed_value_for
    WriteAttr->>TypedValue: typed_value_for(field_name, value)
    create participant Mongoize1 as Fields::Standard#35;mongoize
    TypedValue->>Mongoize1: fields[key].mongoize(value)
    create participant Mongoize2 as Date.mongoize
    Mongoize1-->>Mongoize2: Date.mongoize(value)
    create participant Mongoize3 as String#35;__mongoize_time__
    Mongoize2->>Mongoize3: value.__mongoize_time__
    Mongoize3->>Mongoize2: time
    Mongoize2->>Mongoize1: date
    Mongoize1->>TypedValue: date
    TypedValue->>WriteAttr: date
    Lifecycle->>WriteAttr: date
    deactivate Lifecycle
    WriteAttr->>FieldAssign: date
    FieldAssign->>DocumentProcess2: date
    DocumentProcess2->>DocumentProcess1: date
    DocumentProcess1->>DocumentConstruct:
    Lifecycle->>DocumentConstruct:
    deactivate Lifecycle
    DocumentConstruct->>DocumentNew: document
    DocumentNew->>Document.create: document
    Lifecycle->>Document.create:
    deactivate Lifecycle
    Document.create->>Script: document
```
