#!/usr/bin/env ruby

require_relative "../sansom.rb"
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

s.start