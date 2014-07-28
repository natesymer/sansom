#!/usr/bin/env ruby

require "rack"

# Sansom
# The ultra-tiny web framework

class Sansom
  InvalidRouteError = Class.new StandardError
  NoRoutesError = Class.new StandardError
  
  HTTP_VERBS = [
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "PATCH",
    "OPTIONS"
  ].freeze

  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze
  
  # Accessors
  
  def items
    @items ||= {}
    
    if self.class.instance && self != self.class.instance
      return @items + self.class.instance.items
    end

    @items
  end
  
  def regexes
    @regexes ||= {}
    
    if self.class.instance && self != self.class.instance
      return @regexes + self.class.instance.regexes
    end

    @regexes
  end
  
  def self.instance
    @@instances ||= {}
    @@instances[self.to_s]
  end
  
  def self.instance=(instance)
    @@instances ||= {}
    @@instances[self.to_s] = instance
  end
  
  # Rack
  
  def call env
    r = Rack::Request.new env

    return NOT_FOUND if items.empty?
    
    pair = items[r.request_method]
      .map { |path, item| 
        [regexes[path].match(r.path_info), item, path] rescue [nil, nil, nil]
      }
      .reject { |match_data, item, path|
        match_data.nil?
      }
      .last rescue []
    
    return NOT_FOUND if pair.count != 3
      
    md = pair[0]
    captures = md.captures
    md.names.each_with_index { |name, i| r.params[name] = captures[i] }
    
    item = pair[1]
    path = pair[2]
    
    puts item
    
    case item
    when Proc
      item.call r
    when Sansom
      # truncate the path
      _env = env.dup
      _env["PATH_INFO"] = r.path_info[path.length..-1]
      puts _env["PATH_INFO"]
      puts item.items
      item.call _env
    else
      raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
    end
  end
  
  def start
    raise NoRoutesError if items.empty?
    run self
  end
  
  def self.start
    instance.start if instance
    new.start unless instance
  end
  
  # DSL
  
  def method_missing(meth, *args, &block)
    if block
      super unless map_path meth, args[0], block
    elsif args.count == 2
      super unless map_path meth, args[0], args[1]
    else
      super
    end
  end
  
  # Expose the routing API to the subclass
  def self.method_missing(meth, *args, &block)
    instance = new
    instance.method_missing(meth, *args, &block) rescue super
  end
  
  private
  
  def regexify path
    s = path.split("/")
          .reject(&:empty?)
          .map { |p|
            if p.start_with? ":"
              "(?<#{p[1..-1]}>.*)"
            else
              p
            end
          }
          .join("/")
    s << "/?"
    
    Regexp.new s
  end
  
  def map_path http_method, path, item
    return false if item == self
    
    verb = http_method.to_s.strip.upcase
    return false unless HTTP_VERBS.include? verb
    
    case item
    when Proc, Sansom
      self.items[verb] ||= {}
      self.items[verb][path] = item
    else
      return false
    end
    
    regexes[path] = regexify path
    true
  end
end