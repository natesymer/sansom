#!/usr/bin/env ruby

require "json"
require_relative "../lib/sansom" rescue require "sansom"

class Users
  include Sansomable
  def template
    get "/show/<id>.json" do |r|
      [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
    end
    
    get "/:id/statustwoasdf" do |r|
      puts "MATCHING STATUSTWOASDF"
      [200, {}, ["Okay"]]
    end
    
    get "/:id/avatar.<format>" do |r|
      puts "MATCHING AVATAR"
      [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
    end
  end
end

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "application/json" }, [{ :service_name => "url_params.rb" }.to_json]]
end

s.get "/thing/:id/shitty" do |r|
  [200, { "Content-Type" => "application/json" }, ["SHIT!!!"]]
end

s.get "/thing/:id/food.<format>" do |r|
  [200, { "Content-Type" => "application/json" }, [r.params.to_json]]
end

s.map "/users/", Users.new

s.start 2000