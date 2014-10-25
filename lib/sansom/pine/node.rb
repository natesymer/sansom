#!/usr/bin/env ruby

# represents a node on the routing tree

# No regexes are used once a node is initialized

module Pine  
  class Node
    WILDCARD_REGEX = /<(\w*)\b[^>]*>/.freeze
    URLPATHSAFE_REGEX = /[^a-zA-Z0-9_-]/.freeze
    ROOT = "/"
    
    attr_reader :name # node "payload" data
    attr_reader :parent # node reference system
    attr_reader :wildcard, :wildcard_range # wildcard data
    attr_reader :rack_app, :subsansoms, :blocks # mapping
    attr_reader :end_seq, :start_seq
    attr_reader :wildcard_delim, :semiwildcard_delim

    # Pine::Node.new "asdf", "$", "?" # creates a node with $ as the wildcard delimiter and ? as the semiwildcard delimiter
    # Pine::Node.new "asdf", "#" # creates a node with # as the wildcard delimiter and the default semiwildcard delimiter
    # Pine::Node.new "asdf" # creates a node with the default delimiters
    # Pine::Node.new # creates root node
    # Delimiters can be any length
    def initialize name=ROOT, wc_delim=":", swc_delim="<"
      raise ArgumentError, "Delimiters must not be safe characters in a URL path." if wc_delim.match(URLPATHSAFE_REGEX) rescue false
      raise ArgumentError, "Delimiters must not be safe characters in a URL path." if swc_delim.match(URLPATHSAFE_REGEX) rescue false
      @name = name.freeze
      @children = {}
      @blocks = {}
      @subsansoms = []
      @wildcard_delim = wc_delim
      @semiwildcard_delim = swc_delim
      
      unless root?
        if @name.start_with? wildcard_delim
          @wildcard_range = Range.new(0, -1).freeze
          @wildcard = @name[wc_delim.length..-1].freeze
          @start_seq = "".freeze
          @end_seq = "".freeze
        else
          r = ['<','>'].include?(semiwildcard_delim) ? WILDCARD_REGEX : /#{swc_delim}(\w*)\b[^#{swc_delim}]*#{swc_delim}/
          m = @name.match r
          unless m.nil?
            o = m.offset 1
            @wildcard_range = Range.new(o.first-1, (-1*(m.string.length-o.last+1))+1).freeze # calc `last` rel to the last char idx
            @wildcard = @name[wildcard_range.first+semiwildcard_delim.length..wildcard_range.last-semiwildcard_delim.length].freeze
            @start_seq = @name[0..wildcard_range.first-1].freeze
            @end_seq = wildcard_range.last == -1 ? "" : @name[wildcard_range.last+1..-1].freeze
          end
        end
      end
    end
    
    def inspect
      "#<#{self.class}: #{name.inspect}, #{dynamic? ? "Wildcard: '" + wildcard + "' #{wildcard_range.inspect}, " : "" }#{@children.count} children, #{leaf? ? "leaf" : "internal node"}>"
    end
    
    def siblings
      s = parent.children.dup
      s.delete name
      s.values
    end
    
    def children
      @children.values
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
    
    # WARNING: Sansom's biggest bottleneck
    def [] comp
      case
      when comp.nil? || comp.empty? then raise ArgumentError, "Invalid path component."; nil
      when @children.empty? then nil
      when @children.member?(comp) then @children[comp]
      when @children.count == 1 && [@wildcard_next, @swildcard_next].any? then @children.values.first
      else
        @children.values.detect { |c| c.dynamic? && comp.start_with?(c.start_seq) && comp.end_with?(c.end_seq) }
      end
    end
    
    # chainable
    def << comp
      c = self[comp]
      
      if c.nil?
        c = self.class.new comp
        c.instance_variable_set "@parent", self
      #  children.reject! { |_,c| c.leaf? } if c.wildcard?
        @children[comp] = c
      end

      @swildcard_next = true if c.semiwildcard?
      @wildcard_next = true if c.wildcard?
      
      c
    end
  end
end
