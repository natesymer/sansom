#!/usr/bin/env ruby

require "rack"
require_relative "./sansom/pine"
require_relative "./rack/fastlint.rb"

module Sansomable
  InvalidRouteError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
  ROUTE_METHODS = HTTP_VERBS+[:map]
  RACK_HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
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
      if @before_block && @before_block.arity == 1
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
    
      if @after_block && @after_block.arity == 2
        ares = @after_block.call r, res
        return ares if Rack::Fastlint.response ares
      end
    
      res
    rescue StandardError => e
      b = @error_blocks[e.class]
      raise e if b.nil?
      b.call e, r
    end
  end
  
  def start port=3001
    raise NoRoutesError if tree.leaf?
    Rack::Handler.pick(RACK_HANDLERS).run self, :Port => port
  end
  
  def error error_key, &block
    @error_blocks ||= {}
    @error_blocks[error_key] = block
  end
  
  def before &block
    @before_block = block
  end
  
  def after &block
    @after_block = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item
    return super unless item != self
    return super unless ROUTE_METHODS.include? meth
    tree.map_path path, item, meth
  end
end

Sansom = Class.new Object
Sansom.include Sansomable
