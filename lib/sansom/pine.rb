#!/usr/bin/env ruby

# Path routing tree

module Pine
  Result = Struct.new :item, :remaining_path, :url_params

  class Content
    attr_reader :items, :map
    
    def initialize
      @items = []
      @map = {}
    end
    
    def set k,v
      @items << v if k == :map
      @map[k] = v unless k == :map
    end
  end
  
  class Node
    attr_reader :name, :parent, :content

    def initialize name
      @name = name
      @content = Content.new
      @children = {}
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
      return @children[k] if @children.member? k
      c = @children.values.first
      return c if (c.wildcard? rescue false)
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
    
    def parse_path path
      c = path.split "/"
      c[0] = '/'
      c.delete_at(-1) if c[-1].empty?
      c
    end
    
    def map_path path, item, key
      parse_path(path).inject(self) { |node, comp| node << comp }.content.set key, item
      path
    end
    
    def match path, verb
      matched_comps = []
      matched_params = {}
      
      walk = parse_path(path).inject self do |node, comp|
        break node if node.leaf?
        next node[comp] if node.root?
        
        c = node[comp]
        break node if c.nil?
        matched_comps << comp
        matched_params[c.name[1..-1]] = comp if c.wildcard?
        c
      end

      return nil if walk.nil?
      return nil if walk.root?

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
