#!/usr/bin/env ruby

# Path routing tree

# Custom tree implementation for path routing

# Custom features:
# 1. Trimming: Limit a node to a single element

module Pine
  class Node
    attr_reader :name
    attr_accessor :content
    attr_accessor :parent
  
    def initialize name, content=Content.new
      @name = name
      @content = content
      @children = {}
      @parent = nil
      @trimmed = false
    end
  
    # returns a node for chaining
    def <<(node)
      if trimmed?
        # Add to first child
        children.first << node
      else
        node.parent = self
        @children[node.name] = node
        node
      end
    end
    
    def create_if_necessary name
      unless @children.keys.include? name
        child = self.class.new name
        child.parent = self
        @children[name] = child
      end
      @children[name]
    end
  
    def root
      n = self
      n = n.parent while !n.root?
      n
    end
    
    def children
      @children.values
    end
    
    def trim(node)
      @trimmed = true
      @children.clear
      @children[node.name] = node
      self
    end
    
    def []=(k,v)
      self << Node.new(k, v)
    end
  
    def [](k)
      @children[k]
    end
  
    def root?
      @parent.nil?
    end
  
    def leaf?
      @children.count == 0
    end
    
    def trimmed?
      @trimmed
    end
    
    def inspect(level=0)
      if root?
        print "*"
      else
        print "|" unless parent.parent.children.last == parent rescue false
        print(' ' * level * 4)
        print(parent.children.last == self ? "+" : "|")
        print "---"
        print(leaf? ? ">" : "+")
      end

      puts " #{name} #{content.map rescue "fuck"}" 

      children.each { |child| child.inspect(level + 1) if child } # Child might be 'nil'
    end
  end
  
  class Content
    attr_accessor :items
    attr_accessor :map
    
    def initialize
      @items = []
      @map = {}
    end

    def []=(k,v)
      @items << v if k == :map
      @map[k] = v unless k == :map
    end
  
    def [](k)
      @items[k] if Numeric === k
      @map[k] unless Numeric === k
    end
  end
end
