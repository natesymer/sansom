Sansom
==

Flexible, versatile, light web framework named after Sansom street in Philly.

Usage
-

It's pretty simple. Instead of `Class`s storing routes, `Object`s store routes.

There are two ways you can deploy `Sansom`:

    # app.rb
    
    #!/usr/bin/env ruby

	require "sansom"

    s = Sansom.new
    s.get "/" do |r|
      # r is a Rack::Request
      [200, { "Content-Type" => "text/plain" }, ["Hello Sansom"]]
    end
    s.start

Or, the more production-ready version:

    # config.ru
    
    require "sansom"
    
    s = Sansom.new
    
    s.get "/" do |r|
      # r is a Rack::Request
      [200, { "Content-Type" => "text/plain" }, ["Hello Sansom"]]
    end
    
    run s
    
But `Sansom` can do more than just that:

It can be used in a similar fashion to Sinatra:

    # myapi.rb
    
    #!/usr/bin/env ruby
    
    require "sansom"
    
    class MyAPI < Sansom
      # This method is used to define Sansom routes
      def template
        get "/" do |r|
          [200, { "Content-Type" => "text/plain" }, ["Hello Sansom"]]
          # r is a Rack::Request
        end
      end
    end
    
And your `config.ru` file

    # config.ru
    
    require "sansom"
    require "./myapi"
    
    run MyAPI.new
    
Sansom can also map other instances of Sansom to a route. Check this:
    
    # myapi.rb
    
    #!/usr/bin/env ruby
    
    require "sansom"
    
    class MyAPI < Sansom
      # This method is used to define Sansom routes
      def template
        get "/" do |r|
          [200, { "Content-Type" => "text/plain" }, ["Hello Sansom"]]
          # r is a Rack::Request
        end
      end
    end
    
Let's say you've written a new version of your api. No problem.
    
    # app.rb
    
    require "sansom"
    
    s = Sansom.new
    s.map "/v1", MyAPI.new
    s.map "/v2", MyNewAPI.new
    s.start
    
Or maybe you want to mount your Rails/Sinatra/whatever app

    # app.rb
    
    require "sansom"
    
    s = Sansom.new
    s.map "/api", SinatraApp.new
    s.map "/", RailsApp.new
    s.start
    
Lastly, any object can become a "`Sansom`" through a mixin:

    # mixin.ru
    
    class Mixin < Hash
      include Sansomable
  
      def template
        get "/sansomable" do |r|
          [200, { "Content-Type" => "text/plain"}, ["Sansomable Hash"]]
        end
      end
    end
    
    run Mixin.new
    
If you look at how `Sansom` is defined, it makes sense:

    Sansom = Class.new Object
    Sansom.include Sansomable
    
Matching
-

`Sansom` uses trees to match routes. It follows a certain set of rules:

  - A matching order is enforced:
  	1. The route matching the path and verb
  	2. The first Subsansom that matches the route & verb
  	3. The first mounted non-`Sansom` rack app matching the route

Notes
-

- `Sansom` does not pollute _any_ `Object` methods, including `initialize`
- `Sansom` is under **140** lines of code at the time of writing. This includes
	* Everything above
	* Custom routing
