#!/usr/bin/env ruby

# Path routing tree

module Pine
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
      @wildcard
    end
    
    def [] k
      return @children[k] || @children.values.first
    #  child = @children[k] || @child.values.first
     # return child unless child.nil?
      
     # @children[k] || @children.values.first.wildcard? ? @children.values.first : nil
    end
    
    def create_and_save comp
      child = self.class.new comp
      child.instance_variable_set "@parent", self
      @children[comp] = child
      child
    end
    
    def << comp      
      if comp.start_with? ":"
        @wildcard = true
        @children.clear
        create_and_save comp
      else
        child = @children[comp]
        child = create_and_save comp if !child || (!child && child.leaf? && !child.wildcard?)
        child
      end
    end

    def parse_path path
      c = path.split "/"
      c[0] = '/'
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
        break node if node.leaf?
        matched_comps << comp unless comp == "/"
        child = node[comp]
        matched_params[child.name[1..-1]] = comp if node.wildcard?
        child
      end

      return nil if walk.root? rescue true

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
end
