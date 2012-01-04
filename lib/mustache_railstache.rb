require 'action_view'
require 'active_support'
require 'active_support/core_ext/class/attribute'
require 'mustache'

class Mustache

  # Remember to use {{{yield}}} (3 mustaches) to skip escaping HTML
  # Using {{{tag}}} will skip escaping HTML so if your mustache methods return
  # HTML, be sure to interpolate them using 3 mustaches.

  # Override Mustache's default HTML escaper to only escape strings that
  # aren't marked `html_safe?`
  def escapeHTML(str)
    str.html_safe? ? str : CGI.escapeHTML(str)
  end

  class Railstache < Mustache
    attr_accessor :view

    def method_missing(method, *args, &block)
      view.send(method, *args, &block)
    end

    def respond_to?(method, include_private=false)
      super(method, include_private) || view.respond_to?(method, include_private)
    end

    # function to return a view, routing around standard rails viewing. Useful to get a view object
    # in a controller, and subsequently render to json and return this to the client, which then renders
    def self.for(options={})
      stache = new(false)
      stache.view = options[:view]
      options.delete(:view)

      options.each do |key, value|
        stache[key] = value
      end

      stache.init
      return stache
    end

    def initialize(run=true)
      init if run
    end

    #override this function to do the initialize
    def init
    end

    def to_hash
      rv = {}
      (methods - Mustache::Railstache.instance_methods).each do |m|
        rv[m] = send(m)
      end
      rv
    end

    # Redefine where Mustache::Rails templates locate their partials:
    #
    # (1) in the same directory as the current template file.
    # (2) in the shared templates path (can be configured via Config.shared_path=(value))
    #
    def partial(name)
      partial_name = "_#{name}.#{Config.template_extension}"
      template_dir = Pathname.new(self.template_file).dirname
      partial_path = File.expand_path("#{template_dir}/#{partial_name}")
      unless File.file?(partial_path)
        partial_path = "#{Config.shared_path}/#{partial_name}"
      end
      File.read(partial_path)
    end

    # You can change these defaults in, say, a Rails initializer or
    # environment.rb, e.g.:
    #
    # Mustache::Rails::Config.template_base_path = Rails.root.join('app', 'templates')
    module Config
      def self.template_base_path
        @template_base_path ||= ::Rails.root.join('app', 'templates')
      end

      def self.template_base_path=(value)
        @template_base_path = value
      end

      def self.template_extension
        @template_extension ||= 'html.mustache'
      end

      def self.template_extension=(value)
        @template_extension = value
      end

      def self.shared_path
        @shared_path ||= ::Rails.root.join('app', 'templates', 'shared')
      end

      def self.shared_path=(value)
        @shared_path = value
      end
    end

    class TemplateHandler

      class_attribute :default_format
      self.default_format = :mustache

      # @return [String] its evaled in the context of the action view
      # hence the hack below
      #
      # @param [ActionView::Template]
      def call(template)
        mustache_class = mustache_class_from_template(template)
        template_file = mustache_template_file(template)

        <<-MUSTACHE
          mustache = ::#{mustache_class}.new
          mustache.template_file = #{template_file.inspect}
          mustache.view = self
          mustache[:yield] = content_for(:layout)
          mustache.context.update(local_assigns)
          variables = controller.instance_variable_names
          variables -= %w[@template]

          if controller.respond_to?(:protected_instance_variables)
            variables -= controller.protected_instance_variables
          end

          variables.each do |name|
            mustache.instance_variable_set(name, controller.instance_variable_get(name))
          end

          # Declaring an +attr_reader+ for each instance variable in the
          # Mustache::Rails subclass makes them available to your templates.
          mustache.class.class_eval do
            attr_reader *variables.map { |name| name.sub(/^@/, '').to_sym }
          end

          mustache.render
        MUSTACHE
      end

      # In Rails 3.1+, #call takes the place of #compile
      def self.call(template)
        new.call(template)
      end

    private

      def mustache_class_from_template(template)
        const_name = ActiveSupport::Inflector.camelize(template.virtual_path.to_s)
        defined?(const_name) ? const_name.constantize : Mustache
      end

      def mustache_template_file(template)
        "#{Config.template_base_path}/#{template.virtual_path}.#{Config.template_extension}"
      end

    end
  end
end

#::ActiveSupport::Dependencies.autoload_paths << Rails.root.join("app", "views")
::ActionView::Template.register_template_handler(:rb, Mustache::Railstache::TemplateHandler)
