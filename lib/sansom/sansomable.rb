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
  VALID_VERBS = HTTP_VERBS+ACTION_VERBS
  RACK_HANDLERS = ["puma","unicorn","thin","webrick"].freeze

  def _tree
    if @tree.nil?
      @tree = Pine::Node.new "ROOT"
      template if respond_to? :template
      routes if respond_to? :routes
    end
    @tree
  end
  
  def _call_route *args, handler
    raise RouteError, "Handler is nil." if handler.nil?
    raise RouteError, "Route handler's arity is incorrect." if handler.respond_to?(:arity) && args.count != handler.arity
    raise NoMethodError, "Route handler doesn't respond to call(env). Route handlers must be blocks or valid rack apps." unless handler.respond_to? :call
    res = handler.call *args
    raise ResponseError, "Response must either be a rack response, string, or object" unless Rack::Lint.fastlint res # custom method
    res = [200, {}, [res.to_str]] if res.respond_to? :to_str
    res
  end
  
  def _not_found
    return _call_route r, @not_found_block unless @not_found_block.nil?
    [404, {}, ["Not found."]]
  end
  
  def call env
    return _not_found if _tree.singleton? # no routes
    m = _tree.match env["PATH_INFO"], env["REQUEST_METHOD"]
    return _not_found if m.nil?
    
    begin
      r = Rack::Request.new env
      r.path_info = m.remaining_path unless m.item.is_a? Proc
      
      unless m.url_params.empty?
        r.GET.merge! m.url_params
        r.params.merge! m.url_params
      end
      
      res = _call_route r, @before_block if @before_block # call before block
      res ||= _call_route (m.item.is_a?(Proc) ? r : r.env), m.item # call route handler block
      res ||= _call_route r, res, @after_block if @after_block # call after block
      res ||= _not_found # return response if not found
      res
    rescue => e
      raise if @error_blocks.nil? || @error_blocks.empty?
      b = @error_blocks[e.class] || @error_blocks[:default]
      raise if b.nil?
      b.call e, r
    end
  end
  
  def start port=3001, handler=""
    raise RouteError, "There are no mapped routes." if _tree.leaf?
    begin
      h = Rack::Handler.get handler.to_s
    rescue LoadError, NameError
      h = Rack::Handler.pick(RACK_HANDLERS)
    ensure
      h.run self, :Port => port
    end
  end
  
  def error error_key=nil, &block
    (@error_blocks ||= {})[error_key || :default] = block
  end
  
  def before &block
    raise ArgumentError, "Before filter blocks must take one argument." if block.arity != 1
    @before_block = block
  end
  
  def after &block
    raise ArgumentError, "After filter blocks must take two arguments." if block.arity != 2
    @after_block = block
  end
  
  def not_found &block
    raise ArgumentError, "Not found blocks must take one argument." if block.arity != 1
    @not_found_block = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item && item != self
    return super unless VALID_VERBS.include? meth
    return super unless item.respond_to? :call
    _tree.map_path path, item, meth
  end
end