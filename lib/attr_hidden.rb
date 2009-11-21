module AttrHidden #:nodoc:

  ATTR_HIDDEN_ALTERNATIVE = { :hidden => [:except, :attr_hidden_attributes, :without_attr_hidden, :without_attr_visible],
                              :visible => [:only, :attr_visible_attributes, :without_attr_visible, :without_attr_hidden]}

  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  def to_xml_with_attr_hidden(options = {}, &block) #:nodoc:
    to_xml_without_attr_hidden(set_attr_hidden_options(options, :hidden), &block)
  end

  def to_json_with_attr_hidden(options = {}, &block) #:nodoc:
    to_json_without_attr_hidden(set_attr_hidden_options(options, :hidden), &block)
  end

  def as_json_with_attr_hidden(options = {}, &block) #:nodoc:
    as_json_without_attr_hidden(set_attr_hidden_options(options, :hidden), &block)
  end

  def to_xml_with_attr_visible(options = {}, &block) #:nodoc:
    to_xml_without_attr_visible(set_attr_hidden_options(options, :visible), &block)
  end

  def to_json_with_attr_visible(options = {}, &block) #:nodoc:
    to_json_without_attr_visible(set_attr_hidden_options(options, :visible), &block)
  end

  def as_json_with_attr_visible(options = {}, &block) #:nodoc:
    as_json_without_attr_visible(set_attr_hidden_options(options, :visible), &block)
  end

private

  def set_attr_hidden_options(options, chain) #:nodoc:
    option, retriever, skip, other_skip = ATTR_HIDDEN_ALTERNATIVE[chain]
    options.delete other_skip
    options[option] = options.delete(option){[]}.concat self.class.send(retriever) unless options.delete(skip)
    options
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
  module ClassMethods

    @@attr_visible_attributes = Hash.new { |hash, key| hash[key] = [] }
    @@attr_hidden_attributes = Hash.new { |hash, key| hash[key] = [] }

    def attr_visible_attributes #:nodoc:
      @@attr_visible_attributes[name]
    end

    def attr_hidden_attributes #:nodoc:
      @@attr_hidden_attributes[name]
    end

    # Mark a set of attributes to be hidden from serialization.
    #
    # This has the effect of automatically using <code>:except => attributes</code> in all serializations.
    def attr_hidden(*attributes)
      attr_hidden_attributes.concat attributes
      set_attr_hidden_method_chains :attr_hidden
    end

    # Mark a set of attributes to be the only ones visible during serialization.
    #
    # This has the effect of automatically using <code>:only => attributes</code> in all serializations.
    def attr_visible(*attributes)
      attr_visible_attributes.concat attributes
      set_attr_hidden_method_chains :attr_visible
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

private
    def set_attr_hidden_method_chains(chain) #:nodoc:
      alias_method_chain :to_xml, chain unless method_defined?("to_xml_without_#{chain}".to_sym)
      alias_method_chain :to_json, chain unless method_defined?("to_json_without_#{chain}".to_sym)
      alias_method_chain :as_json, chain unless method_defined?("as_json_without_#{chain}".to_sym)
    end
  
  end
end