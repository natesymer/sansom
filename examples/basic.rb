#!/usr/bin/env ruby

require_relative "../lib/sansom" rescue require "sansom"

s = Sansom.new # create a sansom object

# this is called before any handlers are called
s.before do |r|
  puts "(#{s.class.to_s}) #{r.request_method.upcase} #{r.path_info}"
  [200, {}, ["Hijacked by before!"]] if Random.new.rand(2) == 1
end

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["root"]]
end

s.get "/something" do |r|
  [200, { "Content-Type" => "text/plain" }, ["something"]]
end

s.start 2000