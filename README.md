# facet_for

facet_for is a collection of FormBuilder helpers that speed up the process of creating complex search forms with [Ransack](http://github.com/ernie/ransack).

For many searches, it can be as simple as adding this inside your ```search_form_for```:

```ruby
<%= f.facet_for(:field_name) -%>
```

facet_for will use the database column type to choose an appropriate Ransack predicate, then create both the label and field. It will also work for ```has_many``` and ```belongs_to``` associations.

## Installation

Add ```gem 'facet_for'``` in your Gemfile

## Options

Many options in facet_for can be overridden by passing hash options.

### Predicates

To choose an alternate predicate, pass ```:type => :predicate```.

Most of the Ransack predicates are supported:

* Contains - ```:type => :cont```
* Doesn't Contain - ```:type => :not_cont```
* Starts With - ```:type => :start```
* Doesn't Start With - ```:type => :not_start```
* Ends With - ```:type => :end```
* Doesn't End With - ```:type => :not_end```
* Is Null - ```:type => :null```
* Is Not Null - ```:type => :not_null```
* True - ```:type => :true```
* False - ```:type => :false```
* Greater Than or Equal - ```:type => :gte```
* Less Than or Equal - ```:type => :lte```

As well as several special cases and meta-predicates specific to facet_for:

#### Between

By default, when passing a ```date``` or ```datetime``` column to facet_for, it will use the ```:type => :between``` predicate.

Rather than generating a single field, ```:type => :between``` creates one ```:type => :lte``` and one ```:type => :gte``` field with a single label. This makes searching ranges of dates or numbers painless.

#### Collections

* Collection - ```:type => :collection```

By default, when passing a ```has_many``` or ```belongs_to``` association into facet_for, it will choose the ```:collection``` predicate. This produces a ```collection_select``` with the unique options for that association.

When using ```:type => :collection``` on a column in the database, rather than an association, it defaults to all unique options.

To pass specific options, use ```:collection => []``` to pass an array of options. This may either be a flat array of strings (eg ```['Blue', 'Red', 'Green']), a flat array of objects (```SomeModel.all```), or a nested array of name and value pairs.

* Contains Any - ```:type => :cont_any```

```:type => :cont_any``` behaves in a nearly identical manner to ```:type => :collection```, except that the collection is rendered as a series of check boxes rather than a ```collection_select```.

### Custom Labels

By default, facet_for will determine label text based on a combination of the field name and the predicate. This can be overwritten by specifying ```:label => 'Your Label Here'```.
