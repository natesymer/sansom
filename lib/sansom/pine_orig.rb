#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It is capable of matching both wildcards
# and semiwildcards.
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup. You could say it matches a route in
# something resembling logarithmic time, but really is linear time
# due to child lookups (Children are just iterated over)

module Pine
  Result = Struct.new :item, :remaining_path, :matched_path, :url_params
  WILDCARD_REGEX = /<(\w*)\b[^>]*>/

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
    attr_reader :name, :parent, :content, :wildcard, :wildcard_range

    def initialize name
      @name = name.freeze
      @content = Content.new
      @children = {}
      if @name.start_with? ":"
        @wildcard_range = [0, 0].freeze
      else
        m = @name.match WILDCARD_REGEX
        unless m.nil?
          o = m.offset 1
          @wildcard_range = Range.new(o.first-1, (-1*(m.string.length-o.last+1))+1).freeze # translate to relative to the end of the string
        end
      end
      @wildcard = @name[@wildcard_range.first+1..@wildcard_range.last-1].freeze if @wildcard_range
    end
    
    def root?
      @parent.nil?
    end
  
    def leaf?
      @children.empty?
    end
    
    def singleton?
      leaf? && root?
    end
    
    def semiwildcard?
      wildcard? && @wildcard_range.first == @wildcard_range.last && @wildcard_range.last == 0
    end
    
    def wildcard?
      @wildcard && !@wildcard.empty?
    end

    def [] k
      return nil if @children.empty?
      return @children[k] if @children.member? k # try normal lookup
      
      # try complete wildcard
      if @children.count == 1
        c = @children.values.first
        return c if (c.wildcard? rescue false)
      end
      
      # try semiwildcard
    #  @children.each do |name,c|
    #    next unless c.semiwildcard?
    #    start_w = c.name[0..c.wildcard_range.first-1]
    #    end_w = c.name[c.wildcard_range.last+1..-1]
    #    puts c.inspect if name.start_with?(start_w) && name.end_with?(end_w)
    #    return c if name.start_with?(start_w) && name.end_with?(end_w)
    #  end
    end
    
    def << comp
      child = self[comp]
      
      if child.nil?
        child = self.class.new comp
        child.instance_variable_set "@parent", self
        @children.reject!(&:leaf?) if child.wildcard? && !child.semiwildcard?
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
      matched_length = 0
      matched_params = {}
      
      walk = parse_path(path).inject self do |node, comp|
        break node if node.leaf?
        c = node[comp]
        next c if node == self # node.root?
        break node if c.nil?
        matched_length += comp.length+1
        matched_params[c.wildcard] = comp[c.wildcard_range] if c.wildcard?
        c
      end
      
      return nil if walk.nil? || walk.root?

      c = walk.content
      remaining = path[matched_length..-1]
      matched = path[0..matched_length-1]

      match = c.map[verb.downcase.to_sym]
      match ||= c.items.detect { |i| sansom?(i) && i._tree.match(remaining, verb) }
      match ||= c.items.detect { |i| !sansom?(i) }

      return nil if match.nil?
      
      Result.new match, remaining, matched, matched_params
    end
    
    def sansom? obj
      obj.singleton_class.include? Sansomable
    end
  end
end
