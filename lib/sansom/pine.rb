#!/usr/bin/env ruby

#require "sansom"

# Path routing tree

module Pine
  class Node
    attr_reader :name
    attr_accessor :content,:parent
  
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
      @children[k]
    end
    
    def create comp
      child = self.class.new comp
      child.parent = self
      child
    end
    
    # Chainable
    def << comp      
      if comp.start_with? ":"
        @wildcard = true
        @children.clear
        child = create(comp)
        @children[comp] = child
        child
      else
        child = @children[comp]

        if !child || (!child && child.leaf? && !child.wildcard?)
          child = create(comp)
          @children[comp] = child
        end
        
        child
      end
    end

    def parse_path path
      path.split("/").reject(&:empty?).unshift("/")
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
        matched_params[child.name[1..-1]] = comp if child.wildcard?
        child
      end

      return nil if walk.root? rescue true

      c = walk.content
      subpath = path.sub "/#{matched_comps.join("/")}", ""
      
      match = c.map[verb.downcase.to_sym]
      match ||= c.items.select(&method(:sansom?)).reject { |s| s.tree.match(subpath, verb).nil? }.first
      match ||= c.items.reject(&method(:sansom?)).first

      return nil if match.nil?
      
      Result.new match, subpath, matched_params
    end
    
    def sansom? obj
      obj.singleton_class.include? Sansomable
    end
  end
  
  class Result
    attr_reader :item, :remaining_path, :url_params

    def initialize item, remaining_path, url_params
      @item = item
      @remaining_path = remaining_path
      @url_params = url_params
    end
    
    def sansom?
      @item.singleton_class.include? Sansomable
    end
  end
  
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
