#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It is capable of matching both wildcards
# and semiwildcards.
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup. You could say it matches a route in
# something resembling logarithmic time, but really is linear time
# due to child lookups (Children are just iterated over)
#
# Additionally, Pine caches. So, for an app with mostly static
# route paths, a Sansom app will be as fast as a Rack app after
# the Sansom app's routes have been matched and cached.

module Pine
  Result = Struct.new :item, :remaining_path, :matched_path, :url_params
  WILDCARD_REGEX = /<(\w*)\b[^>]*>/.freeze
  
  # The class you use.
  class Tree
    def initialize
      @cache = {}
      @root = Pine::Node.new
    end
    
    # map_path "/food", Subsansom.new, :map
    # map_path "/", my_block, :get
    def map_path path, item, key
      @cache.clear
      @root.map_path path, item, key
    end
    
    # match "/", :get
    def match path, verb
      k = verb.to_s + path.to_s
      return @cache[k] if @cache.member? k
      r = @root.match path, verb
      @cache[k] = r
      r
    end
    
    def empty?
      @root.leaf?
    end
  end
  
  class Node
    ROOT = "/"
    
    attr_reader :name # node "payload" data
    attr_reader :parent, :children # node reference system
    attr_reader :wildcard, :wildcard_range # wildcard data
    attr_reader :rack_app, :subsansoms, :blocks # mapping

    def initialize name=ROOT
      @name = name.freeze
      @children = {}
      @parent = nil
      @blocks = {}
      @subsansoms = []
      @rack_app = nil
      
      if root?
        if name.start_with? ":"
          @wildcard_range = Range.new(0, 0).freeze
        else
          m = name.match WILDCARD_REGEX
          unless m.nil?
            o = m.offset 1
            @wildcard_range = Range.new(o.first-1, (-1*(m.string.length-o.last+1))+1).freeze # translate to relative to the end of the string
          end
        end
        @wildcard = name[wildcard_range.first+1..wildcard_range.last-1].freeze unless wildcard_range.nil?
      end
    end
    
    def root?
      name == ROOT
    end
  
    def leaf?
      children.empty?
    end
    
    def singleton?
      leaf? && root?
    end
    
    def semiwildcard?
      !wildcard_range.nil? && wildcard_range.size != 1
    end
    
    def wildcard?
      !wildcard_range.nil? && wildcard_range.size == 1
    end

    # WARNING: This has a potential to be a bottleneck
    def [] k
      case
      when children.empty? then nil
      when children.member?(k) then children[k] # static lookup
      else
        children.each do |name, child|
          break child if child.wildcard?
          next unless child.semiwildcard?
          next unless name.start_with? name[0..c.wildcard_range.first-1]
          next unless name.end_with? name[c.wildcard_range.last+1..-1]
          break child
        end
      end
    end
    
    def << comp
      child = self[comp]
      
      if child.nil?
        child = self.class.new comp
        child.instance_variable_set "@parent", self
        @children.reject!(&:leaf?) if child.wildcard?
        @children[comp] = child
      end

      child
    end
    
    # returns all non-root path components
    # path_comps("/my/path/")
    # => ["my", "path"]
    def path_comps path
      path[1..(path.last == "/" ? -2 : -1)].split "/"
    end
    
    def map_path path, item, key
      node = root? ? self : path_comps(path).inject(self) { |n, comp| n << comp }
      if key == :map && !item.is_a?(Proc)
        if item.singleton_class.include?(Sansomable)
          node.subsansoms << item
        else
          node.rack_app = item
        end
      else
        node.blocks[key] = item
      end
      path
    end
    
    def match path, verb
      return nil if leaf?
      matched_length = 0
      matched_params = {}
      
      walk = path_comps(path).inject self do |n, comp|
        c = n[comp]
        break if c.nil?
        if !c.root?
          matched_length += comp.length+1
          matched_params[c.wildcard] = comp[c.wildcard_range] if c.wildcard?
        end
        c
      end
      
      return nil if walk.nil?

      remaining = path[matched_length..-1]
      match = walk.blocks[verb.downcase.to_sym]
      match ||= walk.subsansoms.detect { |i| i._tree.match remaining, verb }
      match ||= walk.rack_app

      return nil if match.nil?
      
      Result.new match, remaining, path[0..matched_length-1], matched_params
    end
  end
end
