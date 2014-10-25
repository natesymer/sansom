#!/usr/bin/env ruby

require "json"
require_relative "../lib/sansom" rescue require "sansom"

class Users
  include Sansomable
  def template
    get "/<id>.json" do |r|
      [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
    end
    
    get "/:id/status" do |r|
      [200, {}, ["Okay"]]
    end
    
    get "/:id/avatar.<format>" do |r|
      [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
    end
  end
end

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "application/json" }, [{ :service_name => "url_params.rb" }.to_json]]
end

s.get "/:id/food.<format>" do |r|
  [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
end

s.map "/users/", Users.new

s.start 2000