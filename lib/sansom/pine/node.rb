#!/usr/bin/env ruby

# represents a node on the routing tree

# No regexes are used once a node is initialized

require "pine/matcher"

class Pine
  class Node
    LineageError = Class.new StandardError
    ROOT = "/".freeze
    
    attr_reader   :name # node "payload" data
    attr_accessor :parent # node reference system
    attr_reader   :children # hash of non-patterned children
    attr_reader   :dynamic_children # array of patterned chilren
    attr_reader   :rack_app, :subsansoms, :blocks # mapping

    def initialize name=ROOT
      @name = name.freeze
      @matcher = Pine::Matcher.new name
      @children = {}
      @dynamic_children = []
      @blocks = {}
      @subsansoms = []
    end
    
    def inspect
      "#<#{self.class}: #{children.count+dynamic_children} children, #{leaf? ? "leaf" : "internal node"}>"
    end
    
    def == another
      parent == another.parent &&
      name == another.name
    end

    def <=> another
      return nil unless another.is_a? Pine::Node
      return 0 if self == another
      return -1 if another.ancestor? self
      return 1 if another.child? self
      nil
    end
    
    def child? anothrer
      another.ancestor? self
    end
    
    def ancestor? another
      n = self
      n = n.parent until n == another || n.root?
      n == another
    end
    
    def ancestors
      a = [self]
      a << a.last.parent until a.last.root?
      a[1..-1]
    end
    
    def root?; name == ROOT; end
    def leaf?; children.empty? && dynamic_children.empty? && subsansoms.empty? && rack_app.nil?; end
    
    def dynamic?; @matcher.dynamic?; end
    def splats comp; @matcher.splats comp; end
    def mapping comp; @matcher.mapping comp; end
    
    # WARNING: Sansom's biggest bottleneck
    # Partially chainable: No guarantee the returned value responds to :child or :[]
    def child comp
      raise ArgumentError, "Invalid path component." if comp.nil? || comp.empty?
      return @children[comp] if @children.member? comp
      dynamic_children.detect { |c| c.instance_variable_get("@matcher").matches? comp }
    end
    
    alias_method :[], :child
    
    # chainable
    def add_child! comp
      raise ArgumentError, "Invalid path component." if comp.nil? || comp.empty?
      c = self[comp] || self.class.new(comp)
      c.parent = self
      c
    end
    
    alias_method :<<, :add_child!
    
    def parent= p
      return if @parent == p
      
      # remove from old parent's children structure
      unless @parent.nil?
        @parent.children.delete name
        @parent.dynamic_children.reject! { |c| c.name == name }
      end
      
      unless p.nil?
        # add to new parent's children structure
        if name.start_with(':')
          p.children.reject! { |_,c| c.leaf? }
          p.dynamic_children.reject!(&:leaf?)
        end
        p.dynamic_children << self
      end

      @parent = p # set new parent
    end
  end
end
