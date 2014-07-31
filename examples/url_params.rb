#!/usr/bin/env ruby

require "json"
require_relative "../lib/sansom" rescue require "sansom"

class Users
  include Sansomable
  def template
    get "/users/:secondary_id/profile" do |r|
      
      [200, { "Content-Type" => "text/plain" }, [r.params.to_json]]
    end
  end
end

u = Users.new
s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["root"]]
end

s.get "/:id/something" do |r|
  puts r.params.inspect
  [200, { "Content-Type" => "text/plain" }, ["something"]]
end

s.map "/:id/", u

s.start 2000