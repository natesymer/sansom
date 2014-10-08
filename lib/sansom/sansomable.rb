#!/usr/bin/env ruby

require "rack"
require_relative "./pine"
require_relative "../rack/fastlint"
require_relative "../rack/handler_helper"

module Sansomable
  InvalidRouteError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
  ROUTE_METHODS = HTTP_VERBS+[:map]
  RACK_HANDLER_ORDER = ["puma", "unicorn", "thin"].freeze
  NOT_FOUND = [404, {}, ["Not found."]].freeze
  
  def tree
    if @tree.nil?
      @tree = Pine::Node.new "ROOT"
      template if respond_to? :template
    end
    @tree
  end
  
  def call env
    return NOT_FOUND if tree.leaf? && tree.root?
  
    r = Rack::Request.new env
    m = tree.match r.path_info, r.request_method
  
    return NOT_FOUND if m.nil?
    
    begin
      if @before_block
        bres = @before_block.call r
        return bres if Rack::Fastlint.response bres
      end

      if m.url_params.count > 0
        q = r.params.merge m.url_params
        s = q.map { |p| p.join '=' }.join '&'
        r.env["rack.request.query_hash"] = q
        r.env["rack.request.query_string"] = s
        r.env["QUERY_STRING"] = s
        r.instance_variable_set "@params", r.POST.merge(q)
      end
    
      case m.item
      when Proc then res = m.item.call r
      else
        raise InvalidRouteError, "Route handlers must be blocks or valid rack apps." unless m.item.respond_to? :call
        r.env["PATH_INFO"] = m.remaining_path
        res = m.item.call r.env
      end
    
      if @after_block
        ares = @after_block.call r, res
        return ares if Rack::Fastlint.response ares
      end
    
      res
    rescue StandardError => e
      b = @error_blocks[e.class] || @error_blocks[:default]
      raise e if b.nil?
      b.call e, r
    end
  end
  
  def start handler=nil, port=3001
    raise NoRoutesError if tree.leaf?
    
    handlers = Rack::Handler.handlers
    handlers[handler.to_s] = const_get(handler.to_s) unless handler.nil?

    handler = handlers.keys.find do |h|
      begin
        require "rack/handler#{handler.gsub(/^[A-Z]+/) { |pre| pre.downcase }.gsub(/[A-Z]+[^A-Z]/, '_\&').downcase}"
      rescue
        false
      else
        true
      end
    end
    
    handlers[handler].run self, :Port => port
  end
  
  def error error_key=nil, &block
    (@error_blocks ||= {})[error_key || :default] = block
  end
  
  def before &block
    raise ArgumentError, "" if block.arity != 1
    @before_block = block
  end
  
  def after &block
    raise ArgumentError, "" if block.arity != 2
    @after_block = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item && item != self
    return super unless ROUTE_METHODS.include? meth
    tree.map_path path, item, meth
  end
end