#!/usr/bin/env ruby

require "rack"

class Sansom
  InvalidRouteError = Class.new StandardError
  NoRoutesError = Class.new StandardError
  
  HTTP_VERBS = ["GET","HEAD","POST","PUT","DELETE","PATCH","OPTIONS"].freeze
  HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze
  
  def self.new
    s = super
    s.instance_variable_set "@items", Hash[HTTP_VERBS.map { |v| [v, {}] }]
    s.instance_variable_set "@regexes", {}
    s.template if s.respond_to? :template
    s
  end
  
  def template
    get "/" do |r|
      [200, {"Content-Type" => "text/plain"}, "Welcome to Sansom!"]
    end
  end
  
  def call env
    return NOT_FOUND if @items.empty?
    
    r = Rack::Request.new env

    pair = @items[r.request_method]
      .map { |path, item| 
        [@regexes[path].match(r.path_info), item, path] rescue [nil, nil, nil]
      }.reject { |match_data, item, path|
        match_data.nil?
      }
      .last || []

    return NOT_FOUND if pair.count != 3
    
    matchdata = pair[0]
    item = pair[1]
    path = pair[2]
    
    captures = matchdata.captures
    matchdata.names.each_with_index { |name, i| r.params[name] = captures[i] }

    case item
    when Proc
      item.call r
    when Sansom
      _env = env.dup
      _env["PATH_INFO"] = r.path_info[path.length..-1]
      item.call _env
    else
      raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
    end
  end
  
  def start port=3001
    raise NoRoutesError if @items.empty?
    Rack::Handler.pick(HANDLERS).run self, :Port => port # :Port really is capitalized
  end
  
  def method_missing(meth, *args, &block)
    if block && args.count == 1
      super unless map_path meth, args[0], block
    elsif args.count == 2
      super unless map_path meth, args[0], args[1]
    else
      super
    end
  end
  
  private
  
  def regexify path, close=true
    s = "^/"
    s << path.split("/")
          .reject(&:empty?)
          .map { |p|
            if p.start_with? ":"
              "(?<#{p[1..-1]}>.*)"
            else
              p
            end
          }
          .join("/")
    s << "/?" if close
    s << "$" if close
    
    Regexp.new s
  end
  
  def map_path http_method, path, item
    return false if item == self
    
    verb = http_method.to_s.strip.upcase
    return false unless HTTP_VERBS.include? verb
    
    case item
    when Proc
      @items[verb][path] = item
      @regexes[path] = regexify path, true
      true
    when Sansom
      @items[verb][path] = item
      @regexes[path] = regexify path, false
      true
    else
      false
    end
  end
end