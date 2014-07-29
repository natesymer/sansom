#!/usr/bin/env ruby

# Custom tree implementation for path routing

# Custom features:
# 1. Trimming: Limit a node to a single element

module Pine
  class Node
    attr_accessor :parent
  
    def initialize name, content
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
      end
      node
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
    end
    
    def []=(k,v)
      self << Node.new k, v
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
  end
  
  class Content
    def initialize
      
    end
  end
end
