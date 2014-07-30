#!/usr/bin/env ruby

require "rack"
require_relative "./sansom/pine"

module Sansomable
  InvalidRouteError = Class.new StandardError
  
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options].freeze
  HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze

  def tree
    @tree ||= nil
    if @tree.nil?
      @tree = Pine::Node.new("ROOT", nil)
      template if respond_to? :template
    end
    @tree
  end
  
  def before_block
    @before_block ||= nil
  end

  def match verb, path
    components = s_parse_path(path)
    matched_components = []
    matched_parameters = {}
    
    walk = components.inject(tree) do |node, component|
      if node.leaf?
        node
      else
        matched_components << component unless component == "/"
        node[component]
      end
    end
    
    return nil if walk.root?

    c = walk.content
    matched_path = "/" + matched_components.join("/")

    match = c[verb.downcase.to_sym] # Check for route
    match ||= c.items.select(&method(:sansom?)).reject { |item| item.match(verb, path.sub(matched_path, "")).nil? }.first rescue nil # Check subsansoms
    match ||= c.items.reject(&method(:sansom?)).first rescue nil # Check for mounted rack apps
    [match, matched_path]
  end
  
  def call env
    return NOT_FOUND if tree.leaf?
    
    r = Rack::Request.new env

    m = match r.request_method, r.path_info
    item = m.first
    
    if item.nil?
      NOT_FOUND
    else
      if before_block
        res = before_block.call r
        return res if res[0].is_a?(Numeric) && res[1].is_a?(Hash) && res[2].respond_to?(:each) rescue false
      end
      
      if item.is_a? Proc
        item.call r
      elsif sansom? item
        r.path_info.sub! m[1], ""
        item.call(r.env)
      else
        raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
      end
    end
  end
  
  def start port=3001
    raise NoRoutesError if tree.children.empty?
    Rack::Handler.pick(HANDLERS).run self, :Port => port
  end
  
  def before(&block)
    @before_block = block
  end
  
  def method_missing(meth, *args, &block)
    path, item = *args.dup.push(block)
    return super unless path && item
    return super if item == self
    return super unless HTTP_VERBS.include?(meth) || meth == :map
    
    n = s_parse_path(path).inject(tree) { |node, comp| node.create_if_necessary comp }
    n.content[meth] = item
  end
  
  private
  
  def sansom? obj
    return true if obj.is_a? Sansom
    return true if obj.class.included_modules.include? Sansomable
    false
  end

  def s_parse_path path
    path.split("/").reject(&:empty?).unshift("/")
  end
end

Sansom = Class.new Object
Sansom.include Sansomable
