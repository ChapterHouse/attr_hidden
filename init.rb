$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'attr_hidden'
ActiveRecord::Base.class_eval { include AttrHidden }
