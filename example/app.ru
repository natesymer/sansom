#!/usr/bin/env ruby

require_relative "../sansom.rb"
require_relative "./resources/foods.rb"
=begin
require_relative "./resources/foods.rb"

class App < Sansom
  get "/food", Food.new
end

App.start

=end

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["sushi"]]
end

s.get "/food" do Food.new

#s.start

run s