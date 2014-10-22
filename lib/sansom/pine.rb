#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It is capable of matching both wildcards
# and semiwildcards.
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup. You could say it matches a route in
# something resembling logarithmic time, but really is linear time
# due to child lookups (Children are just iterated over)

module Pine
  Result = Struct.new :item, :remaining_path, :matched_path, :url_params
  WILDCARD_REGEX = /<(\w*)\b[^>]*>/.freeze
  
  class Tree
    def initialize
      @cache = {}
      @root = Pine::Node.new
    end
    
    def map_path path, item, key
      @cache.clear
      @root.map_path path, item, key
    end
    
    def match path, verb
      k = verb + " " + path
      return @cache[k] if @cache.member k
      r = @root.match path, verb
      @cache[k] = r
      r
    end
    
    def empty?
      @root.leaf?
    end
  end
  
  class Node
    ROOT_NAME = "ROOT"
    
    attr_reader :name # node "payload" data
    attr_reader :parent, :children # node reference system
    attr_reader :wildcard, :wildcard_range # wildcard data
    attr_reader :rack_app, :subsansoms, :blocks # mapping

    def initialize name=ROOT_NAME
      @name = name.freeze
      @children = {}
      @parent = nil
      
      if name != ROOT_NAME
        @blocks = {}
        @subsansoms = []
        @rack_app = nil
        if name.start_with? ":"
          @wildcard_range = [0, 0].freeze
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
      parent.nil?
    end
  
    def leaf?
      children.empty?
    end
    
    def singleton?
      leaf? && root?
    end
    
    def semiwildcard?
      wildcard? && !(wildcard_range.first == wildcard_range.last && wildcard_range.last == 0)
    end
    
    def wildcard?
      !wildcard.nil? && !wildcard.empty?
    end

    def [] k
      return nil if children.empty?
      return children[k] if children.member? k # try normal lookup
      
      # try complete wildcard
      if children.count == 1
        c = children.values.first
        return c if (c.wildcard? rescue false)
      end
      
      # try semiwildcard
      children.each do |name,c|
        next unless c.semiwildcard?
        start_w = c.name[0..c.wildcard_range.first-1]
        end_w = c.name[c.wildcard_range.last+1..-1]
        return c if name.start_with?(start_w) && name.end_with?(end_w)
      end
      
      nil
    end
    
    def << comp
      child = self[comp]
      
      if child.nil?
        child = self.class.new comp
        child.instance_variable_set "@parent", self
        @children.reject!(&:leaf?) if child.wildcard? && !child.semiwildcard?
        @children[comp] = child
      end

      child
    end
    
    def parse_path path
      c = path.split "/"
      c[0] = '/'
      c.delete_at(-1) if c[-1].empty?
      c
    end
    
    def map_path path, item, key
      node = parse_path(path).inject(self) { |n, comp| n << comp }
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
      
      walk = parse_path(path).inject self do |n, comp|
        c = n[comp]
        case c
        when self then c
        when nil then break nil # break n
        else
          matched_length += comp.length+1
          matched_params[c.wildcard] = comp[c.wildcard_range] if c.wildcard?
          c
        end
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
