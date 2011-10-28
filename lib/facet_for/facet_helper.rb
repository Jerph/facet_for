module FacetHelper
  def render_facets(object, view)
    facet_html = ''

    view.meta_select.meta_select_facets.each do |facet|
      facet_html << FacetFor.create_facet(:object => object,
                                          :object_name => 'q',
                                          :type => facet.predicate.to_sym,
                                          :column_name => facet.column_name,
                                          :params => params)
    end
    facet_html.html_safe
  end
end

ActionView::Base.send :include, FacetHelper
