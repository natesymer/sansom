#!/usr/bin/env ruby

require "rack"

class Sansom
  InvalidRouteError = Class.new StandardError
  NoRoutesError = Class.new StandardError
  
  HTTP_VERBS = ["GET","HEAD","POST","PUT","DELETE","PATCH","OPTIONS"].freeze
  HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze
  CONFLICING_ROUTES = [500, {"Content-Type" => "text/plain"}, ["Conflicting routes were specified."]].freeze
  SUBITEMS_KEY = "x_subitem".freeze
  #PATH_KEY = "x_path".freeze
  
  def self.new
    s = super
    s.instance_variable_set "@map", {}
    s.template if s.respond_to? :template
    s
  end
  
  # Recursive matching
  # TODO: Use a TREE instead of this regex BS
  
  # Matching is done in order of ascending index.
  # Precedence order:
  # 1. A single Subsansom
  # 2. A single Route (multiple routes is impossible)
  # 3. A single Rack app
  
  def match path, verb
    matches = @map
                .map { |regex,meths| [regex.match(path), meths] }
                .reject { |md, meths| md.nil? }
                .map { |md, meths| [md, meths.select { |k,v| k == SUBITEMS_KEY || k == verb }] }
                .reject { |md, meths| meths.empty? }
                .map { |md, meths| [md.names.zip(md.captures) rescue nil, meths] }
                
    return 404 if matched.empty?
                
    # params are from regex matching the URL
    routes = matches.reject { |params, meths| meths.member? SUBITEMS_KEY }.map { |params, meths| [params, meths[verb]] }
    subitems = matches
                .select { |params, meths| meths.member? SUBITEMS_KEY }
                .map { |params, meths| [params, meths[SUBITEMS_KEY]].flatten }
                
    rack_apps = subitems.reject { |params, item, pth| Sansom === item }.map { |params, item, pth| item }
                  
    subsansoms = subitems
                    .select { |params, item, pth| Sansom === item }
                    .reject { |params, item, pth| Numeric === item.match(path[pth.length..-1], verb) }
                    .map { |params, item, pth| [params, item] }

    if subsansoms.count == 1
      return Hash[[:params, :item].zip(subsansoms.first)]
    elsif routes.count == 1
      return Hash[[:params, :item].zip(routes.first)]
    elsif rack_apps.count == 1
      return { :item => rack_apps.first }
    else
      return 500
    end
  end
  
  def call env
    return NOT_FOUND if @map.empty?
    
    r = Rack::Request.new env
    
    m = match r.path_info, r.request_method
    
    case m
    when 500
      CONFLICING_ROUTES
    when 404
      NOT_FOUND
    when Hash
      params = m[:params] || {}
      item = m[:item]
      
      case item
      when Proc
        item.call r
      when Sansom
        # TODO: Needs work
        item.call(env.merge({ "PATH_INFO" => r.path_info[meths[PATH_KEY].length..-1] }))
      else
        raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
      end
    end
    
    
  end
  
  def start port=3001
    raise NoRoutesError if @map.empty?
    Rack::Handler.pick(HANDLERS).run self, :Port => port
  end
  
  def method_missing(meth, *args, &block)
    _args = args.push block
    
    if _args.count >= 2
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
          .map { |p| p.start_with?(":") ? "(?<#{p[1..-1]}>.*)" : p }
          .join("/")
    s << "/?$" if close
    
    Regexp.new s
  end
  
  def map_path http_method, path, item
    return false if item == self
    
    verb = http_method.to_s.strip.upcase
    return false unless HTTP_VERBS.include? verb

    case item
    when Proc
      regex = regexify path, true
      @map[regex] ||= {}
      @map[regex][verb] = item
      true
    when Sansom
      _path = path.dup
      _path = _path[0..-2] if _path.end_with? "/"
      regex = regexify path, false
      @map[regex] ||= {}
      @map[regex][SUBITEMS_KEY] ||= []
      @map[regex][SUBITEMS_KEY].push([item, _path])
      true
    else
      false
    end
  end
end