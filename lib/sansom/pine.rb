#!/usr/bin/env ruby

# Path routing tree

module Pine
  Result = Struct.new :item, :remaining_path, :url_params
  
  class Content
    attr_accessor :items, :map
    
    def initialize
      @items = []
      @map = {}
    end

    def []= k,v
      @items << v if k == :map
      @map[k] = v unless k == :map
    end
  
    def [] k
      @items[k] if Numeric === k
      @map[k] unless Numeric === k
    end
  end
  
  class Node
    attr_reader :name, :parent
    attr_accessor :content
  
    def initialize name, content=Content.new
      @name = name
      @content = content
      @children = {}
      @parent = nil
    end
  
    def root?
      @parent.nil?
    end
  
    def leaf?
      @children.count == 0
    end
    
    def wildcard?
      @name.start_with? ":"
    end
    
    def [] k
      child = @children[k]
      return child unless child.nil?
      child = @children.values.first
      return child if child.wildcard?
      nil
     # return @children[k] || @children.values.first
    end
    
    def create_and_save comp
      child = self.class.new comp
      child.instance_variable_set "@parent", self
      @children[comp] = child
      child
    end
    
    def << comp
      if comp.start_with? ":"
        @children.clear
        create_and_save comp
      else
        child = @children[comp]
        child = create_and_save comp if !child || (!child && child.leaf? && !child.wildcard?)
        child
      end
    end

    def parse_path path, include_root=true
      c = path.split "/"
      if include_root
        c[0] = '/'
      else
        c.delete_at(0) if c[0].empty?
      end
      c.delete_at(-1) if c[-1].empty?
      c
    end
    
    def map_path path, item, key
      parse_path(path).inject(self) { |node, comp| node << comp }.content[key] = item
      path
    end
    
    def match path, verb
      matched_comps = []
      matched_params = {}
      
      walk = parse_path(path).inject self do |node, comp|
        next node[comp] if node.name == "ROOT"
        matched_comps << comp unless node.leaf?
        child = node[comp]
        matched_params[child.name[1..-1]] = comp if child.wildcard?
        child
      end

      return nil if walk.nil?
      return nil if walk.root? #rescue true

      c = walk.content
      subpath = path.sub "/#{matched_comps.join("/")}", ""
      
      match = c.map[verb.downcase.to_sym]
      match ||= c.items.detect { |i| sansom?(i) && i.tree.match(subpath, verb) }
      match ||= c.items.detect { |i| !sansom?(i) }

      return nil if match.nil?
      
      Result.new match, subpath, matched_params
    end
    
    def sansom? obj
      obj.singleton_class.include? Sansomable
    end
  end
end
