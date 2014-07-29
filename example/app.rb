#!/usr/bin/env ruby

require "rack"
require_relative "../sansom.rb"
#require_relative "./resources/foods.rb"

class Food < Sansom
  def template
    get "/sushi" do |r|
      [200, { "Content-Type" => "text/plain"}, ["sushi"]]
    end

    get "/vegan" do |r|
      [200, { "Content-Type" => "text/plain"}, ["vegan"]]
    end
  end
end

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["root"]]
end

s.get "/food", Food.new

s.start