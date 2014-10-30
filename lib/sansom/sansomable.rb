#!/usr/bin/env ruby

require "rack"
require_relative "./pine"
require_relative "../rack/fastlint"

module Sansomable
  RouteError = Class.new StandardError
  ResponseError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
  ACTION_VERBS = [:map].freeze
  VALID_VERBS = (HTTP_VERBS+ACTION_VERBS).freeze
  RACK_HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOTFOUND_TEXT = "Not found.".freeze

  def _pine
    if @_pine.nil?
      @_pine = Pine.new
      template if respond_to? :template
      routes if respond_to? :routes
    end
    @_pine
  end
  
  def _call_handler handler, *args
    raise ArgumentError, "Handler must not be nil." if handler.nil?
    raise ArgumentError, "Handler must be a valid rack app." unless handler.respond_to? :call
    raise ArgumentError, "Handler cannot take all passed args." if handler.respond_to?(:arity) && args.count != handler.arity
    res = handler.call *args
    res = res.finish if res.is_a? Rack::Response
    raise ResponseError, "Response must either be a rack response, string, or object" unless Rack::Lint.fastlint res # custom method
    res = [200, {}, [res.to_str]] if res.respond_to? :to_str
    res
  end
  
  def _not_found
    return _call_route @_not_found, r unless @_not_found.nil?
    [404, {}, [NOTFOUND_TEXT]]
  end
  
  def call env
    return _not_found if _pine.empty? # no routes
    m = _pine.match env["PATH_INFO"], env["REQUEST_METHOD"]
    return _not_found if m.nil?
    
    r = Rack::Request.new env
    
    begin
      r.path_info = m.remaining_path unless Proc === m.handler
      
      unless m.params.empty?
        r.env["rack.request.query_string"] = r.query_string # now Rack::Request#GET will return r.env["rack.request.query_hash"]
        (r.env["rack.request.query_hash"] ||= {}).merge! m.params # update the necessary field in the hash
        r.instance_variable_set "@params", nil # tell Rack::Request to recalc Rack::Request#params
      end
      
      res = _call_handler @_before, r if @_before # call before block
      res ||= _call_handler m.handler, (Proc === m.handler ? r : r.env) # call route handler block
      res ||= _call_handler @_after, r, res if @_after # call after block
      res ||= _not_found
      res
    rescue => e
      _call_handler @_error_blocks[e.class], e, r rescue raise e
    end
  end
  
  def start port=3001, handler=""
    raise RouteError, "No routes." if _pine.empty?
    begin
      h = Rack::Handler.get handler.to_s
    rescue LoadError, NameError
      h = Rack::Handler.pick(RACK_HANDLERS)
    ensure
      h.run self, :Port => port
    end
  end
  
  def error error_key=nil, &block
    (@_error_blocks ||= Hash.new { |h| h[:default] })[error_key || :default] = block
  end
  
  def before &block
    raise ArgumentError, "Before filter blocks must take one argument." if block && block.arity != 1
    @_before = block
  end
  
  def after &block
    raise ArgumentError, "After filter blocks must take two arguments." if block && block.arity != 2
    @_after = block
  end
  
  def not_found &block
    raise ArgumentError, "Not found blocks must take one argument." if block && block.arity != 1
    @_not_found = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item && item != self
    return super unless VALID_VERBS.include? meth
    return super unless item.respond_to? :call
    _pine.map_path path, item, meth
  end
end