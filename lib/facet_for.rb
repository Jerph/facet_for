require "facet_for/version"

class ActionView::Helpers::FormBuilder
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::AssetTagHelper

  def facet_for(column, *args)
    options = args.extract_options!

    facet_html = ''

    # Here, we collect information about the facet. What the user doesn't
    # supply, we'll make our best guess for.

    facet = { }
    facet[:model] = @object.klass

    facet[:column] = facet[:model].content_columns.select {                                      |x| x.name == column.to_s }

    # Information about the column. This is used to generate the default
    # label, and to pass the right selector to the Ransack fields.

    facet[:column_name] = options[:column_name]
    facet[:column_type] = options[:column_type]

    # This is the type of field we will render. If this isn't provided, we'll
    # determine this based on facet_column_type

    facet[:type] = options[:type]

    # In the specific case of facet_type == :collection, we'll allow the user
    # to specify their own collection. If it's an association, we'll attempt
    # to provide one.

    facet[:collection] = options[:collection]

    if facet[:column].empty? # facet doesn't exist

      # Is it an association?
      #
      # We check for :singular_name, :plural_name and :singular_id

      if association = associations_for(facet[:model]).select { |x|
          x.plural_name == column.to_s or
          x.plural_name.singularize == column.to_s or
          x.primary_key_name == column.to_s }.uniq

        if association.first.macro == :has_many

          # For a has_many relationship, we want the plural name with _id.
          # Ransack will then look at the _id column for the associated model.
          # This won't work properly on models with nonstandard id column
          # names. That's a problem, but whatevs for the time being.

          facet[:column_name] = "#{association.first.plural_name}_id"

        elsif association.first.macro == :belongs_to

          # If we're dealing with belongs_to, we can assume we just want
          # to look at the foreign key on the current model. Much simpler.

          facet[:column_name] = association.first.foreign_key

        end

        # By default, we want to use a select box with a collection of
        # what this model has_many of. If the user has specified something,
        # we'll run with what they specified.

        facet[:type] = facet[:type] || :collection

        # If the user hasn't specified a collection, we'll provide one now
        # based on this association

        facet[:collection] = facet[:collection] || association.first.klass.all

      else
        return # nothing found
      end
    else

      # We found a column. Let's yank some useful information out of it

      facet[:column] = facet[:column].first
      facet[:column_name] = facet[:column].name
      facet[:column_type] = facet[:column_type] || facet[:column].type
    end

    facet[:type] = facet[:type] || default_facet_type(facet)


    # Insert our label first

    facet_html = "<div class=\"label #{additional_classes(facet)}\">"

    if options[:label]
      facet_html << self.label(column, options[:label])
    else
      facet_html << default_label_for_facet(facet)
    end

    facet_html << "</div>"

    # And now the fields

    facet_html << render_facet_for(facet)

    facet_html.html_safe
  end

  # If the user doesn't pass options[:label], we'll build a default label
  # based on the type of facet we're rendering.

  def default_label_for_facet(facet)
    case facet[:type]
    when :cont
      return self.label("#{facet[:column_name]}_cont".to_sym)
    else
      return self.label("#{facet[:column_name]}")
    end
  end

  # Now that we have our type, we can render the actual form field for
  # Ransack

  def render_facet_for(facet)

    facet_html = "<div class=\"input #{additional_classes(facet)}\">"

    case facet[:type]
    when :cont
      facet_html << self.text_field("#{facet[:column_name]}_cont".to_sym)
    when :collection
      facet_html << self.collection_select("#{facet[:column_name]}_eq".to_sym, facet[:collection], :id, :to_s, :include_blank => true)
    when :between
      facet_html << "From "
      facet_html << self.text_field("#{facet[:column_name]}_gteq".to_sym, :size => 11)
      facet_html << "To "
      facet_html << self.text_field("#{facet[:column_name]}_lteq".to_sym, :size => 11)
    when :gteq
      facet_html << self.text_field("#{facet[:column_name]}_gteq".to_sym, :size => 5)
    when :lteq
      facet_html << self.text_field("#{facet[:column_name]}_gteq".to_sym, :size => 5)
    end

    facet_html << "</div>"
    facet_html
  end

  # If no options[:type] is specified, we'll look at the column type for
  # the column in the model and make an educated guess.

  def default_facet_type(facet)

    case facet[:column_type]
    when :string, :text
      return :cont
    when :datetime, :date, :float, :integer, :double
      return :between
    end
  end

  def additional_classes(facet)
    additional_class = "#{facet[:type]} #{facet[:column_type]}"
  end

  # We can use reflections to determine has_many and belongs_to associations

  def associations_for(model)
    model.reflections.values
  end

end
