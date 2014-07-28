#!/usr/bin/env ruby

require_relative "../../sansom.rb"

class Food < Sansom
  get "/sushi" do |r|
    [200, { "Content-Type" => "text/plain"}, ["sushi"]]
  end

  get "/vegan" do |r|
    [200, { "Content-Type" => "text/plain"}, ["vegan"]]
  end
end