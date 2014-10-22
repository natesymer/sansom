#!/usr/bin/env ruby

require "rack"
require_relative "./pine"
require_relative "../rack/fastlint"

module Sansomable
  RouteError = Class.new StandardError
  HandlerError = Class.new StandardError
  ResponseError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
  ACTION_VERBS = [:map].freeze
  VALID_VERBS = (HTTP_VERBS+ACTION_VERBS).freeze
  RACK_HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOTFOUND_TEXT = "Not found.".freeze

  def _tree
    if @_tree.nil?
      @_tree = Pine::Tree.new
      template if respond_to? :template
      routes if respond_to? :routes
    end
    @_tree
  end
  
  def _call_route handler, *args
    raise RouteError, "Handler is nil." if handler.nil?
    raise RouteError, "Route handler's arity is incorrect." if handler.respond_to?(:arity) && args.count != handler.arity
    raise NoMethodError, "Route handler doesn't respond to call(env). Route handlers must be blocks or valid rack apps." unless handler.respond_to? :call
    res = handler.call *args
    res = res.finish if Rack::Response === res
    raise ResponseError, "Response must either be a rack response, string, or object" unless Rack::Lint.fastlint res # custom method
    res = [200, {}, [res.to_str]] if res.respond_to? :to_str
    res
  end
  
  def _not_found
    return _call_route @_not_found, r unless @_not_found.nil?
    [404, {}, [NOTFOUND_TEXT]]
  end
  
  def call env
    return _not_found if _tree.empty? # no routes
    m = _tree.match env["PATH_INFO"], env["REQUEST_METHOD"]
    return _not_found if m.nil?
    
    r = Rack::Request.new env
    
    begin
      r.path_info = m.remaining_path unless Proc === m.item
      
      unless m.url_params.empty?
        r.GET.merge! m.url_params
        r.params.merge! m.url_params
      end
      
      res = _call_route @_before, r if @_before # call before block
      res ||= _call_route m.item, (Proc === m.item ? r : r.env) # call route handler block
      res ||= _call_route @_after, r, res if @_after # call after block
      res ||= _not_found
      res
    rescue => e
      raise if @_error_blocks.nil? || @_error_blocks.empty?
      b = @_error_blocks[e.class] || @_error_blocks[:default]
      raise if b.nil?
      b.call e, r
    end
  end
  
  def start port=3001, handler=""
    raise RouteError, "No routes." if _tree.empty?
    begin
      h = Rack::Handler.get handler.to_s
    rescue LoadError, NameError
      h = Rack::Handler.pick(RACK_HANDLERS)
    ensure
      h.run self, :Port => port
    end
  end
  
  def error error_key=nil, &block
    (@_error_blocks ||= {})[error_key || :default] = block
  end
  
  def before &block
    raise ArgumentError, "Before filter blocks must take one argument." if block.arity != 1
    @_before = block
  end
  
  def after &block
    raise ArgumentError, "After filter blocks must take two arguments." if block.arity != 2
    @_after = block
  end
  
  def not_found &block
    raise ArgumentError, "Not found blocks must take one argument." if block.arity != 1
    @_not_found = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item && item != self
    return super unless VALID_VERBS.include? meth
    return super unless item.respond_to? :call
    _tree.map_path path, item, meth
  end
end