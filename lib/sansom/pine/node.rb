#!/usr/bin/env ruby

# represents a node on the routing tree.
# does not use any regexes. Rather, it uses
# a custom pattern matching library

require "sansom/pine/matcher"

class Pine
  class Node
    attr_reader   :name # node "payload" data
    attr_accessor :parent # node reference system
    attr_reader   :children # hash of non-patterned children
    attr_reader   :dynamic_children # array of patterned chilren
    attr_reader   :rack_app, :subsansoms, :blocks # mapping

    def initialize n='/'
      @name = n.freeze
      @matcher = Pine::Matcher.new name
      @children = {}
      @dynamic_children = []
      @blocks = {}
      @subsansoms = []
    end
    
    def inspect; "#<#{self.class}: #{children.count+dynamic_children} children, #{leaf? ? "leaf" : "internal node"}>"; end
    
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
    
    def root?; name == '/'; end
    def leaf?; children.empty? && dynamic_children.empty? && subsansoms.empty? && rack_app.nil?; end
    
    def dynamic?; @matcher.dynamic? || name.start_with?(':'); end
    def splats comp; @matcher.splats comp; end
    def mappings comp; @matcher.mappings comp; end
    
    # WARNING: Sansom's biggest bottleneck
    # Partially chainable: No guarantee the returned value responds to :child or :[]
    def child comp
      raise ArgumentError, "Invalid path component." if comp.nil? || comp.empty?
      res   = @children[comp]
      res ||= dynamic_children.detect { |c| c.instance_variable_get("@matcher").matches? comp }
      res
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
        if name.start_with? ':'
          # remove conflicting children
          p.children.reject! { |_,c| c.leaf? }
          p.dynamic_children.reject!(&:leaf?)
        end
        
        if dynamic?
          p.dynamic_children << self # add to new parent's children structure
        else
          p.children[name] = self
        end
      end

      @parent = p # set new parent
    end
  end
end
