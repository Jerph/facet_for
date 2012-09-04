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
    facet[:object] = @object
    facet[:object_name] = @object_name
    # Information about the column. This is used to generate the default
    # label, and to pass the right selector to the Ransack fields.

    facet[:column_name] = column
    facet[:column_type] = options[:column_type]

    facet[:includes] = options[:includes]

    # This is the type of field we will render. If this isn't provided, we'll
    # determine this based on facet_column_type

    facet[:type] = options[:type]

    # Did we pass in the params? Send it down to determine if we have a value.

    facet[:params] = options[:params]

    # Did we pass in a default value?

    facet[:default] = options[:default]

    # In the specific case of facet_type == :collection, we'll allow the user
    # to specify their own collection. If it's an association, we'll attempt
    # to provide one.

    facet[:collection] = options[:collection]

    # Are we labeling it differently?
    facet[:label] = options[:label]

    # How about adding a class?
    facet[:class] = options[:class]

    @facet = FacetFor::Facet.new(facet)

    facet_html << @facet.render_facet

    facet_html.html_safe
  end


end
