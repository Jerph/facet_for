require "facet_for/version"
require "facet_for/form_builder"
require "facet_for/facet_helper"

module FacetFor

  PREDICATES = [
                ['Contains', :cont],
                ['Doesn\'t Contain', :not_cont],
                ['Starts With', :start],
                ['Doesn\'t Start With', :not_start],
                ['Ends With', :end],
                ['Doesn\'t End With', :not_end],
                ['Between', :between],
                ['Is Null', :null],
                ['Is Not Null', :not_null],
                ['Collection', :collection]
               ]

  def self.predicates
    PREDICATES
  end

  # We can use reflections to determine has_many and belongs_to associations

  def self.create_facet(*args)
    options = args.extract_options!

    @facet = Facet.new(options)
    @facet.render_facet.html_safe
  end


  def self.column_options(q)
    column_options = []
    column_options.push([q.klass.to_s, options_for_model(q.klass)])

    q.context.searchable_associations.each do |association|
      association_model = association.camelcase.singularize.constantize
      column_options.push([association_model.to_s,
                           options_for_model(association_model, association)])
    end

    column_options
  end

  def self.field_options(q)
    field_options = options_for_model(q.klass) | q.context.searchable_associations.map { |a| [a.titleize, a.to_sym] }

    field_options
  end

  def self.options_for_model(model, association = nil, grouped = false)
    options = []
    preface = ''

    if association # preface field names for cross model displaying
      preface = "#{association}."
    end

    if model.ransackable_attributes
      options = model.ransackable_attributes.map { |a| [a.titleize, "#{preface}#{a}".to_sym] }
    end

    options
  end

  class Facet
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::AssetTagHelper

    attr_accessor :facet

    def initialize(facet = {})
      @facet = facet

      # If they didn't provide a model, try and use the search object

      if @facet[:object] && @facet[:model].nil?
        @facet[:model] = @facet[:object].klass
      end

      @facet[:column] = @facet[:model].content_columns.select {                                      |x| x.name == @facet[:column_name].to_s }

      if @facet[:column].empty? # facet doesn't exist

        # Is it an association?
        #
        # We check for :singular_name, :plural_name and :singular_id

        if association = associations.select { |x|
          x.plural_name == @facet[:column_name].to_s or
          x.plural_name.singularize == @facet[:column_name].to_s or
          x.primary_key_name == @facet[:column_name].to_s }.uniq and association.count > 0

          if association.first.macro == :has_many
            # For a has_many relationship, we want the plural name with _id.
            # Ransack will then look at the _id column for the associated model.
            # This won't work properly on models with nonstandard id column
            # names. That's a problem, but whatevs for the time being.
            @facet[:association_name] = "#{association.first.plural_name}"
            @facet[:column_name] = "#{association.first.plural_name}_id"
            @facet[:clean_column_name] = "#{association.first.name.to_s.singularize}_id"

          elsif association.first.macro == :belongs_to

            # If we're dealing with belongs_to, we can assume we just want
            # to look at the foreign key on the current model. Much simpler.

            @facet[:association_name] = association.first.name
            @facet[:column_name] = association.first.foreign_key

          end

          # By default, we want to use a select box with a collection of
          # what this model has_many of. If the user has specified something,
          # we'll run with what they specified.

          @facet[:type] = @facet[:type] || :collection

          # If the user hasn't specified a collection, we'll provide one now
          # based on this association. We only want to use distinct values.
          # This could probably be cleaner, but it works.

          @facet[:collection] = @facet[:model].unscoped.joins(@facet[:association_name].to_sym).select("DISTINCT #{clean_column}").where("#{clean_column} IS NOT NULL").map { |m| @facet[:association_name].to_s.singularize.camelcase.constantize.find(m.send(clean_column))  }

        end
      else

        # We found a column. Let's yank some useful information out of it
        @facet[:column] = @facet[:column].first
        @facet[:column_name] = @facet[:column].name
        @facet[:column_type] = @facet[:column_type] || @facet[:column].type
      end

      @facet[:type] = @facet[:type] || default_facet_type

    end

    def associations
      @facet[:model].reflections.values
    end

    # If the user doesn't pass options[:label], we'll build a default label
    # based on the type of facet we're rendering.

    def default_label_for_facet
      case @facet[:type]
      when :true, :false
        return ''
      when :null
        return label("#{@facet[:column_name]}_null",
                     "#{@facet[:column_name].to_s.humanize} Is Null?")
      when :not_null
        return label("#{@facet[:column_name]}_not_null",
                     "#{@facet[:column_name].to_s.humanize} Is Not Null?")
      when :cont, :cont_any
        return label("#{@facet[:column_name]}_cont",
                     "#{@facet[:column_name].to_s.humanize} Contains")
      when :not_cont
        return label("#{@facet[:column_name]}_not_cont",
                     "#{@facet[:column_name].to_s.humanize} Doesn't Contain")
      when :start
        return label("#{@facet[:column_name]}_start",
                     "#{@facet[:column_name].to_s.humanize} Starts With")
      when :not_start
        return label("#{@facet[:column_name]}_not_start",
                     "#{@facet[:column_name].to_s.humanize} Doesn't Start With")
      when :end
        return label("#{@facet[:column_name]}_end",
                     "#{@facet[:column_name].to_s.humanize} Ends With")
      when :not_end
        return label("#{@facet[:column_name]}_not_end",
                     "#{@facet[:column_name].to_s.humanize} Doesn't End With")
      when :between
        return label("#{@facet[:column_name]}",
                     "#{@facet[:column_name].to_s.humanize} Between")
      when :gte
        return label("#{@facet[:column_name]}_gte",
                     "#{@facet[:column_name].to_s.humanize} Greater Than")
      when :lte
        return label("#{@facet[:column_name]}_lte",
                     "#{@facet[:column_name].to_s.humanize} Less Than")
      else
        return label("#{@facet[:column_name]}")
      end
    end

    # Now that we have our type, we can render the actual form field for
    # Ransack

    def render_facet

      # Insert our label first

      facet_html = "<div class=\"facet_label #{additional_classes}\">"

      if @facet[:label]
        facet_html << label("#{@facet[:column_name]}", @facet[:label])
      else
        facet_html << default_label_for_facet
      end

      facet_html << "</div>"

      # And now the fields

      facet_html << "<div class=\"facet_input #{additional_classes}\">"

      case @facet[:type]
      when :cont, :not_cont, :start, :not_start, :end, :not_end, :gteq, :lteq
        facet_html << text_field
      when :cont_any
        collection_type = :array

        if @facet[:collection].nil?
          @facet[:collection] = unique_value_collection
        end

        if @facet[:collection].first.class == 'String'
          collection_type = :string
        end

        @facet[:collection].each do |check|
          facet_html << "<div class=\"facet_input cont_any check_box\">"

          if collection_type == :array
            facet_html << check_box(check[1])
          else
            facet_html << check_box(check)
          end

          if collection_type == :array
            facet_html << label(self.name_for("#{@facet[:column_name]}_#{@facet[:type].to_s}", true), check[0])
          else
            facet_html << label(self.name_for("#{@facet[:column_name]}_#{@facet[:type].to_s}", true), check)
          end

          facet_html << "</div>"
        end

        facet_html
      when :collection
        facet_html << facet_collection
      when :null, :not_null, :true, :false
        facet_html << check_box
      when :between
        facet_html << text_field(:predicate => :gteq)
        facet_html << "<span class=\"facet_divider\">&mdash;</span>"
        facet_html << text_field(:predicate => :lteq)
      end

      facet_html << "</div>"
      facet_html
    end

    # If no options[:type] is specified, we'll look at the column type for
    # the column in the model and make an educated guess.

    def default_facet_type

      case @facet[:column_type]
      when :string, :text
        return :cont
      when :datetime, :date, :float, :integer, :double
        return :between
      end
    end

    def additional_classes
      additional_class = "#{@facet[:type]} #{@facet[:column_type]}"
    end

    def text_field(options = {})
      predicate = options[:predicate] || @facet[:type]
      name = "#{@facet[:column_name]}_#{predicate.to_s}"

      text_field_tag self.name_for(name), @facet[:object].send(name)
    end

    def check_box(value = "1")
      name = "#{@facet[:column_name]}_#{@facet[:type]}"



      if @facet[:type] == :cont_any
        check_box_label =  label_tag(self.name_for(name, true),
                                     value.to_s.humanize)
        check_box_name = self.name_for(name, true)
      else

        label_value = @facet[:column_name].to_s.humanize

        case @facet[:type]
        when :false
          label_value = "Is Not #{label_value}"
        when :null
          label_value += "Is Null"
        when :not_null
          label_value += "Is Not Null"
        end

        check_box_label =  label_tag(self.name_for(name, true), label_value)
        check_box_name = self.name_for(name, false)
      end

      check_box_tag(check_box_name, value, check_box_checked(value)) + check_box_label
    end

    def check_box_checked(value = "1")
      name = "#{@facet[:column_name]}_#{@facet[:type]}"
      selected = @facet[:object].send(name)

      if @facet[:type] == :cont_any
        return (!selected.nil? and selected.include?(value))
      else
        return selected
      end

    end

    def facet_collection
      name = "#{@facet[:column_name]}_eq"
      selected = @facet[:object].send(name)

      # @facet[:collection] should be set if we've given it a valid
      # association, or passed in a collection by hand.
      #
      # this assumes that we want to see all unique values from the database
      # for the given column

      if @facet[:collection].nil?
        @facet[:collection] = unique_value_collection
      end

      if @facet[:collection].class == Array and
          @facet[:collection].first.class == String

        return select_tag self.name_for(name),
        options_for_select(@facet[:collection], selected),
        :include_blank => true
      else
        return select_tag self.name_for(name),
        options_from_collection_for_select(@facet[:collection], :id, :to_s,
                                           selected), :include_blank => true
      end

    end

    def clean_column
      @facet[:clean_column_name] || @facet[:column_name]
    end

    def unique_value_collection
      @facet[:collection] = @facet[:model].unscoped.select("DISTINCT #{clean_column}").where("#{clean_column} IS NOT NULL").map { |m| m.send(@facet[:column_name]) }
    end

    def label(string_name, string_label = nil)
      display_label = string_label || string_name.humanize
      label_tag self.name_for(string_name), display_label
    end

    def name_for(string_name, array = false)
      name = "#{@facet[:object_name]}[#{string_name}]"
      name += '[]' if array

      name.to_sym
    end

  end
end
