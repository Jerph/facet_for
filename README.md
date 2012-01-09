#facet_for

facet_for is a collection of FormBuilder helpers that speed up the process of creating complex search forms with [Ransack](http://github.com/ernie/ransack).

For many searches, it can be as simple as:

```ruby
<%= f.facet_for(:field_name) -%>
```

Based on the type of column in the database, facet_for will choose an appropriate Ransack predicate, and will create both the label and field.

Installation

Add ```gem 'facet_for'``` in your Gemfile
