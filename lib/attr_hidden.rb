module AttrHidden #:nodoc:

  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  # While attr_accessible and attr_protected can prevent changes to attributes during mass assignment they do not address the need to prevent
  # some attributes not being exposed to the requester. With html requests this is usally not a problem as the page is written to not include
  # the private data. However, with the increasing use of REST and clients consuming xml and json data, the need to be able to easily protect
  # this data increases.
  #
  # This plugin addresses this need to hide outgoing attributes when records are being serialized for REST responses. Traditionally this has
  # been done in the controller on an individual method basis. This is time consuming and increases the likelyhood that mistakes will be made.
  # Instead of relying on the controller to add protection, this plugin takes its cues from attr_protected and attr_accessible and moves the
  # responsibility down into the model itself.
  #
  # Consider a model that yields the following with to_xml
  #
  #   <?xml version="1.0" encoding="UTF-8"?>
  #     <item>
  #       <id type="integer">298486374</id>
  #       <name>Shiny Item</name>
  #       <internal-comment>Bob is Bald</internal-comment>
  #       <internal-rating type="integer">7</internal-rating>
  #     </item>
  #
  # By adding either: 
  #
  #   attr_hidden :internal-comment, :internal-rating
  #
  # or
  #
  #   attr_visible :id, :name
  #  
  # to the model, the to_xml would render
  #
  #   <?xml version="1.0" encoding="UTF-8"?>
  #     <item>
  #       <id type="integer">298486374</id>
  #       <name>Shiny Item</name>
  #     </item>
  #
  # Methods can also be included in the serialization by using serialize_method
  #
  # Additionally, these restrictions and included methods will continue to be maintained even during associational includes during serialization.
  module ClassMethods

    @@attr_hidden_attributes = Hash.new { |hash, key| hash[key] = [] }
    @@attr_hidden_methods = Hash.new { |hash, key| hash[key] = [] }
    @@attr_hidden_style = Hash.new
    
    def attr_hidden_attributes #:nodoc:
      @@attr_hidden_attributes[name]
    end

    def attr_hidden_methods #:nodoc:
      @@attr_hidden_methods[name]
    end

    def attr_hidden_style #:nodoc:
      @@attr_hidden_style[name]
    end

    def attr_hidden_style=(style) #:nodoc:
      @@attr_hidden_style[name] = style
    end

    # Mark a set of attributes to be hidden from serialization.
    #
    # This has the effect of automatically using <code>:except => attributes</code> in all serializations.
    def attr_hidden(*attributes)
      if attr_hidden_style != :hidden
        attr_hidden_attributes.clear
        self.attr_hidden_style = :hidden
      end
      attr_hidden_attributes.concat attributes
    end

    # Mark a set of attributes to be the only ones visible during serialization.
    #
    # This has the effect of automatically using <code>:only => attributes</code> in all serializations.
    def attr_visible(*attributes)
      if attr_hidden_style != :visible
        attr_hidden_attributes.clear
        self.attr_hidden_style = :visible
      end
      attr_hidden_attributes.concat attributes
    end

    # Mark a set of methods to always be included during serialization.
    #
    # This has the effect of automatically using <code>:methods => method_names</code> in all serializations.
    def serialize_method(*method_names)
      attr_hidden_methods.concat method_names
    end

    # Mark a set of attributes as nonexistent to the public.
    #
    # They cannot be mass-assigned and will not show up in serializations.
    def attr_nonexistent(*attributes)
      attr_hidden(*attributes)
      attr_protected(*attributes)
    end
  
    # Mark a set of attributes as the only ones available to the public.
    #
    # They are the only ones that can be mass assigned and the only ones to show up in serializations.
    def attr_available(*attributes)
      attr_visible(*attributes)
      attr_accessible(*attributes)
    end

    alias_method :attr_hidden_and_protected, :attr_nonexistent
    alias_method :attr_protected_and_hidden, :attr_nonexistent
    alias_method :attr_visible_and_accessible, :attr_available
    alias_method :attr_accessible_and_visible, :attr_available
  
    def set_attr_hidden_options(options) #:nodoc:
      unless options.delete(:without_attr_hidden)
        option = case attr_hidden_style
                 when :hidden then :except
                 when :visible then :only
                 end
             
        options[option] = (options.delete(option) || []).concat attr_hidden_attributes if option
        options[:methods] = options.delete(:methods){[]}.concat attr_hidden_methods unless attr_hidden_methods.blank?
      end
      options
    end
  
  end
end

module ActiveRecord #:nodoc:
  module Serialization #:nodoc:
    class Serializer #:nodoc:

      def initialize_with_attr_hidden(record, options = nil)
        options = record.class.set_attr_hidden_options(options ? options.dup : {})
        initialize_without_attr_hidden record, options
      end

      alias_method_chain :initialize, :attr_hidden unless method_defined?(:initialize_without_attr_hidden)

    end
  end
end