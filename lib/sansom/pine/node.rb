#!/usr/bin/env ruby

# represents a node on the routing tree

# No regexes are used once a node is initialized

class Pine
  class Node
    LineageError = Class.new StandardError
    WILDCARD_REGEX = /<(\w*)\b[^>]*>/.freeze
    URLPATHSAFE_REGEX = /[^a-zA-Z0-9_-]/.freeze
    ROOT = "/".freeze
    
    attr_reader   :name # node "payload" data
    attr_accessor :parent # node reference system
    attr_reader   :wildcard, :wildcard_range # wildcard data
    attr_reader   :rack_app, :subsansoms, :blocks # mapping
    attr_reader   :end_seq, :start_seq, :min_length # stored information used to match wildcards
    attr_reader   :wildcard_delimeter, :semiwildcard_delimeter # delimiter for wildcard syntax

    # Pine::Node.new "asdf", "$", "?" # creates a node with $ as the wildcard delimiter and ? as the semiwildcard delimiter
    # Pine::Node.new "asdf", "#" # creates a node with # as the wildcard delimiter and the default semiwildcard delimiter
    # Pine::Node.new "asdf" # creates a node with the default delimiters
    # Pine::Node.new # creates root node
    # Delimiters can be any length
    def initialize name=ROOT, wc_delim=":", swc_delim="<"
      raise ArgumentError, "Delimiters must not be safe characters in a URL path." if wc_delim.match URLPATHSAFE_REGEX rescue false
      raise ArgumentError, "Delimiters must not be safe characters in a URL path." if swc_delim.match URLPATHSAFE_REGEX rescue false
      @name = name.freeze
      @children = {}
      @wildcard_children = {}
      @blocks = {}
      @subsansoms = []
      @wildcard_delimeter = wc_delim
      @semiwildcard_delimeter = swc_delim
      
      unless root?
        if @name.start_with? wildcard_delimeter
          @wildcard_range = Range.new(0, -1).freeze
          @wildcard = @name[wildcard_delimeter.length..-1].freeze
          @start_seq = "".freeze
          @end_seq = "".freeze
        else
          r = ['<','>'].include?(semiwildcard_delimeter) ? WILDCARD_REGEX : /#{swc_delim}(\w*)\b[^#{swc_delim}]*#{swc_delim}/
          m = @name.match r
          unless m.nil?
            o = m.offset 1
            @wildcard_range = Range.new(o.first-1, (-1*(m.string.length-o.last+1))+1).freeze # calc `last` rel to the last char idx
            @wildcard = @name[wildcard_range.first+semiwildcard_delimeter.length..wildcard_range.last-semiwildcard_delimeter.length].freeze
            @start_seq = @name[0..wildcard_range.first-1].freeze
            @end_seq = wildcard_range.last == -1 ? "" : @name[wildcard_range.last+1..-1].freeze
          end
        end
      end
      
      @min_length = dynamic? ? start_seq.length + end_seq.length : name.length
    end
    
    def inspect
      "#<#{self.class}: #{name.inspect}, #{dynamic? ? "Wildcard: '" + wildcard + "' #{wildcard_range.inspect}, " : "" }#{@children.count} children, #{leaf? ? "leaf" : "internal node"}>"
    end
    
    def == another
      parent == another.parent &&
      name == another.name
    end
    
    # TODO: check correctness of return values
    def <=> another
      return 0 if n == another
      
      n = self
      n = n.parent until n == another || n.root?
      return 1 if n == another
      
      n = another
      n = n.parent until n == self || n.root?
      return -1 if n == self
      
      raise LinneageError, "Node not in tree."
    end
    
    def detach!
      _set_parent nil
    end
    
    def siblings
      parent.children.dup - self
    end
    
    def children
      hash_children.values
    end
    
    def hash_children
      Hash[@children.to_a + @wildcard_children.to_a]
    end
    
    def child? another
      another.ancestor? self
    end
    
    def ancestor? another
      n = self
      n = n.parent until n == another || n.root?
      n == another
    end
    
    def ancestors
      n = self
      n = n.parent until n.root?
      n
    end
    
    def root?
      name == ROOT
    end
   
    def leaf?
      children.empty? && subsansoms.empty? && rack_app.nil?
    end
    
    def semiwildcard?
      !wildcard_range.nil? && wildcard_range.size != 0
    end
    
    def wildcard?
      !wildcard_range.nil? && wildcard_range.size == 0
    end
    
    # returns true if self is either a wildcard or a semiwildcard
    def dynamic?
      !wildcard_range.nil?
    end
    
    # Bottleneck for wildcard-heavy apps
    def matches? comp
      return comp == name unless dynamic?
      comp.length >= min_length && comp.start_with?(start_seq) && comp.end_with?(end_seq)
    end
    
    # WARNING: Sansom's biggest bottleneck
    # Partially chainable: No guarantee the returned value responds to :child or :[]
    def child comp
      raise ArgumentError, "Invalid path component." if comp.nil? || comp.empty?
      case
      when @children.empty? && @wildcard_children.empty? then nil
      when @children.member?(comp) then @children[comp]
      else @wildcard_children.values.detect { |c| c.matches? comp } end
    end
    
    alias_method :[], :child
    
    # chainable
    def add_child! comp
      raise ArgumentError, "Invalid path component." if comp.nil? || comp.empty?
      c = self[comp] || self.class.new(comp)
      c._set_parent self
      c
    end
    
    alias_method :<<, :add_child!
    
    def _hchildren; @children; end
    def _hwcchildren; @wildcard_children; end

    # returns new parent so its chainable
    def _set_parent p
      return if @parent == p
      
      # remove from old parent's children structure
      unless @parent.nil?
        @parent._hchildren.delete name unless dynamic?
        @parent._hwcchildren.delete name if dynamic?
      end
      
      # add to new parent's children structure
      if wildcard?
        p._hchildren.reject! { |_,c| c.leaf? }
        p._hwcchildren.reject! { |_,c| c.leaf? }
      end
      p._hwcchildren[name] = self
      
      @parent = p # set new parent
    end
  end
end
