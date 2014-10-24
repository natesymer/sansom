#!/usr/bin/env ruby

# Represents a tree of nodes
# Manipulates Pine::Nodes

require_relative "./node"

module Pine
  Match = Struct.new :handler, # Proc/Subsansom/Rack App
                     :remaining_path, # Part of path that wasn't matched, applies to subsansoms
                     :matched_path, # The matched part of a path
                     :params # Wildcard params
                     
  class Tree
    def initialize
      @cache = {}
      @root = Pine::Node.new
    end
    
    # returns all non-root path components
    # path_comps("/my/path/")
    # => ["my", "path"]
    def path_comps path
      path[1..(path[-1] == "/" ? -2 : -1)].split "/"
    end
    
    # map_path "/food", Subsansom.new, :map
    # map_path "/", my_block, :get
    # it's also chainable
    def map_path path, item, key
      @cache.clear

      node = (path == "/") ? @root : path_comps(path).inject(@root) { |n, comp| n << comp } # Fucking ruby interpreter

      if key == :map && !item.is_a?(Proc) # fucking ruby interpreter
        if item.singleton_class.include? Sansomable
          node.subsansoms << item
        else
          node.rack_app = item
        end
      else
        node.blocks[key] = item
      end
      
      self
    end
    
    # match "/", :get
    # TODO: Fix this in relationship to the root node.
    def match path, verb
      k = verb.to_s + path.to_s
      return @cache[k] if @cache.has_key? k

      return nil if @root.leaf?
      
      matched_length = 0
      matched_params = {}

      walk = path_comps(path).inject @root do |n, comp|
        child = n[comp]
        break if child.nil?
        matched_length += comp.length+1
        matched_params[child.wildcard] = comp[child.wildcard_range] if child.dynamic?
        child
      end
      
      return nil if walk.nil?
      
      puts matched_params.inspect

      remaining = path[matched_length..-1]
      match = walk.blocks[verb.downcase.to_sym]
      match ||= walk.subsansoms.detect { |i| i._tree.match remaining, verb }
      match ||= walk.rack_app

      return nil if match.nil?
      
      r = Match.new match, remaining, path[0..matched_length-1], matched_params
      @cache[k] = r
      r
    end
    
    def empty?
      @root.leaf?
    end
  end
end
