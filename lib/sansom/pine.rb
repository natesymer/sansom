#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It uses libpatternmatch (google it) to
# match paths with splats and mappings 
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup. You could say it matches a route in
# something resembling logarithmic time, but really is linear time
# due to child lookups (children are just iterated over)

require_relative "./pine/node"

class Pine
  Match = Struct.new :remaining_path, # Part of path that wasn't matched, applies to subsansoms
                     :matched_path, # The matched part of a path
                     :params # Wildcard params
                     
  def initialize
    @root = Pine::Node.new
    @cache = {}
  end
  
  def empty?
    @root.leaf?
  end
  
  # returns all non-root path components
  # path_comps("/my/path/")
  # => ["my", "path"]
  def path_comps path
    path.nil? || path.empty? ? [] : path[1..(path[-1] == "/" ? -2 : -1)].split('/')
  end
  
  # map_path "/food", Subsansom.new, :map
  # map_path "/", my_block, :get
  # it's also chainable
  def map_path path, handler, key
    @cache.clear

    node = (path == "/") ? @root : path_comps(path).inject(@root) { |n, comp| n << comp }

    if key == :map && !handler.is_a?(Proc)
      if handler.singleton_class.include? Sansomable
        node.subsansoms << handler
      else
        node.rack_app = handler
      end
    else
      node.blocks[key] = handler
    end
    
    self
  end
  
  # match "/", :get
  def match path, verb
    return nil if empty?
    
    k = verb.to_s + path.to_s
    return @cache[k] if @cache.has_key? k
    
    matched_length = 0
    matched_params = { :splat => [] }
    matched_wildcard = false

    walk = path_comps(path).inject @root do |n, comp|
      c = n[comp]
      break n if c.nil?
      matched_length += comp.length+1
      if c.dynamic?
        matched_params.merge c.mapping(comp)
        matched_params[:splat].merge c.splats(comp)
        matched_wildcard = true
      end
      c
    end
    
    return nil if walk.nil?

    remaining = path[matched_length..-1]
    match = walk.blocks[verb.downcase.to_sym]
    match ||= walk.subsansoms.detect { |i| i._pine.match remaining, verb }
    match ||= walk.rack_app

    return nil if match.nil?
    
    r = Match.new match, remaining, path[0..matched_length-1], matched_params
    @cache[k] = r unless matched_wildcard # Only cache static lookups, avoid huge memory usage
    r
  end
end