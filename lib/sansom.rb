#!/usr/bin/env ruby

require "rack"
require "sansom/pine"
#require "tree" # rubytree

module Sansomable
  class TreeContent
    attr_accessor :items
    def initialize
      @items = []
      @map = {}
    end
  
    def []=(k,v)
      @items << v if k == :map
      @map[k] = v unless k == :map
    end
    
    def [](k)
      @items[k] if Numeric === k
      @map[k] unless Numeric === k
    end
  end
  
  InvalidRouteError = Class.new StandardError
  NoRoutesError = Class.new StandardError
  InclusionError = Class.new StandardError
  
  HTTP_VERBS = ["GET","HEAD","POST","PUT","DELETE","PATCH","OPTIONS"].freeze
  HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze

  def tree
    @tree ||= nil
    if @tree.nil?
      @tree = Tree::TreeNode.new("ROOT", "ROOT")
      template if respond_to? :template
    end
    @tree
  end

  # /users/:id/purchase
  # /

  def match http_method, path
    components = s_parse_path(path)
    matched_components = []
    matched_parameters = {}
    
    walk = components.inject(tree) do |node, component| 
      child = node[component]
      
      if child.nil?
        node
      else
        matched_components << component unless component == "/"
        child
      end
    end

    tc = walk.content
    
    return nil if tc == "ROOT"
    
    matched_path = "/" + matched_components.join("/")

    match = tc[http_method] # Check for route
    match ||= tc.items.select(&method(:sansom?)).reject { |item| item.match(http_method, s_truncate_path(path, matched_path)).nil? }.first rescue nil # Check subsansoms
    match ||= tc.items.reject(&method(:sansom?)).first rescue nil # Check for mounted rack apps
    [match, matched_path]
  end
  
  def call env
    return NOT_FOUND if tree.children.empty?
    
    r = Rack::Request.new env

    m = match r.request_method, r.path_info
    item = m.first
    
    if item.nil?
      NOT_FOUND
    elsif Proc === item
      item.call r
    elsif sansom? item
      item.call(env.dup.merge({ "PATH_INFO" => s_truncate_path(r.path_info, m[1]) }))
    else
      raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
    end
  end
  
  def start port=3001
    raise NoRoutesError if tree.children.empty?
    Rack::Handler.pick(HANDLERS).run self, :Port => port
  end
  
  def method_missing(meth, *args, &block)
    _args = args.dup.push block
    super unless _args.count >= 2 
    
    path = _args[0].dup
    item = _args[1].dup
    
    return super if item == self
    
    verb = meth.to_s.strip.upcase
    return super unless HTTP_VERBS.include?(verb) || meth == :map
    verb = :map if meth == :map
    
    components = s_parse_path path
    components.each_with_index.inject(tree) do |node,(component, idx)|
      child = node[component]

      if child.nil?
        newvalue = Tree::TreeNode.new(component, TreeContent.new)
        node << newvalue
        child = newvalue
      end

      child.content[verb] = item if idx == components.count-1
      child
    end
  end
  
  private
  
  def sansom? obj
    return true if Sansom === obj
    return true if obj.class.included_modules.include? Sansomable
    false
  end
  
  def s_parse_path path
    path.split("/").reject(&:empty?).unshift("/")
  end
  
  def s_truncate_path truncated, truncator
    "/" + s_parse_path(truncated)[s_parse_path(truncator).count..-1].join("/")
  end
end

Sansom = Class.new Object
Sansom.include Sansomable
