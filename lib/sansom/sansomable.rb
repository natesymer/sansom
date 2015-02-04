#!/usr/bin/env ruby

require "rack"
require_relative "./pine"
require_relative "../rack/fastlint"

module Sansomable
  RouteError = Class.new StandardError
  ResponseError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
  ACTION_VERBS = [:mount].freeze
  VALID_VERBS = (HTTP_VERBS+ACTION_VERBS).freeze
  RACK_HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND_RESP = [404, {}, ["Not found."]].freeze

  def _pine
    if @_pine.nil?
      @_pine = Pine.new
      routes if respond_to? :routes
    end
    @_pine
  end
  
  def _call_handler handler, *args
    res = handler.call *args
    res = res.finish if res.is_a? Rack::Response
    raise ResponseError, "Response must either be a rack response, string, or object" unless Rack::Lint.fastlint res # custom method
    res = [200, {}, [res.to_str]] if res.respond_to? :to_str
    res
  end
  
  def call env
    raise RouteError, "No routes." if _pine.empty?
    
    handler, remaining_path, _, route_params = _pine.match env["PATH_INFO"], env["REQUEST_METHOD"]
    return NOT_FOUND_RESP if handler.nil?
    
    r = Rack::Request.new env
    
    begin
      r.path_info = remaining_path unless Proc === handler
      
      unless m.params.empty?
        r.env["rack.request.query_string"] = r.query_string # now Rack::Request#GET will return r.env["rack.request.query_hash"]
        (r.env["rack.request.query_hash"] ||= {}).merge! route_params # add route params r.env["rack.request.query_hash"]
        r.instance_variable_set "@params", nil # tell Rack::Request to recalc Rack::Request#params
      end
      
      res   = _call_handler    @_before, r                               if @_before       # call before block
      res ||= _call_handler     handler, (Proc === handler ? r : r.env)                    # call route handler block
      res ||= _call_handler     @_after, r, res                          if @_after && res # call after block
      res ||= _call_handler @_not_found, r                               if @_not_found    # call error block
      res ||= NOT_FOUND_RESP # fallback error message
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
  
  def error error_class=:default, &block
    raise ArgumentError, "Invalid error: #{error_class}" unless Class === error_class || error_class == :default
    (@_error_blocks ||= Hash.new { |h| h[:default] })[error_class] = block
  end
  
  def before &block; @_before = block; end # 1 arg
  def after &block; @_after = block; end # 2 args
  def not_found &block; @_not_found = block; end # 1 arg
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item && item != self
    return super unless VALID_VERBS.include? meth
    return super unless item.respond_to? :call
    _pine.map_path path, item, meth
  end
end