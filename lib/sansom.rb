#!/usr/bin/env ruby

require "rack"
require_relative "./sansom/pine"
require_relative "./rack/fastlint.rb"

module Sansomable
  InvalidRouteError = Class.new StandardError
  HTTP_VERBS = [:get,:head, :post, :put, :delete, :patch, :options, :link, :unlink, :trace].freeze
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
    return NOT_FOUND if tree.leaf?
    
    r = Rack::Request.new env
    
    if @before_block
      res = @before_block.call r
      return res if Rack::Fastlint.response res
    end

    m = tree.match r.path_info, r.request_method

    if m.nil?
      NOT_FOUND
    else
      if m.url_params.count > 0
        q = r.params.merge m.url_params
        s = q.map { |p| p.join '=' }.join '&'
        r.env["rack.request.query_hash"] = q
        r.env["rack.request.query_string"] = s
        r.env["QUERY_STRING"] = s
        r.instance_variable_set "@params", r.POST.merge(q)
      end
      
      if m.item.is_a? Proc
        m.item.call r
      elsif m.item.respond_to? :call
        r.env["PATH_INFO"] = m.remaining_path
        m.item.call r.env
      else
        raise InvalidRouteError, "Route handlers must be blocks or valid rack apps."
      end
    end
  end
  
  def start port=3001
    raise NoRoutesError if tree.leaf?
    Rack::Handler.pick(RACK_HANDLERS).run self, :Port => port
  end
  
  def before &block
    @before_block = block
  end
  
  def method_missing meth, *args, &block
    path, item = *args.dup.push(block)
    return super unless path && item
    return super unless item != self
    return super unless (HTTP_VERBS+[:map]).include?(meth)
    tree.map_path path, item, meth
  end
end

Sansom = Class.new Object
Sansom.include Sansomable
