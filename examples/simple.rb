#!/usr/bin/env ruby

require_relative "../lib/sansom"

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["root"]]
end

s.get "/something" do |r|
  [200, { "Content-Type" => "text/plain"}, ["something"]]
end

s.start 2000