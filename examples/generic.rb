#!/usr/bin/env ruby

require "json"
require_relative "../lib/sansom.rb" rescue LoadError require "sansom"

class Sansom
  def food_response r
    [200, { "Content-Type" => "text/plain"}, [{ :type => self.class.to_s, :name => r.path_info.split("/").reject(&:empty?).last}.to_json]]
  end
end

class Meat < Sansom
  def template
    get "/pork" do |r|
      food_response r
    end
  end
end

class NonAnimal < Sansom
  def template
    get "/quinoa" do |r|
      food_response r
    end
    
    get "/tahini" do |r|
      food_response r
    end
    
    get "/squash" do |r|
      food_response r
    end
  end
end

class AnimalProducts < Sansom
  def template
    get "/eggs" do |r|
      food_response r
    end
  
    get "/milk" do |r|
      food_response r
    end
  end
end

class FoodTypes < Sansom
  def template
    map "/carnivorous", Meat.new
    map "/vegetarian", NonAnimal.new
    map "/vegetarian", AnimalProducts.new
    map "/vegan", NonAnimal.new
  end
end

class Food < Sansom
  def template
    get "/sushi" do |r|
      [200, { "Content-Type" => "text/plain"}, ["Quite delicious, especially cucumber"]]
    end
    
    map "/types", FoodTypes.new
  end
end

s = Sansom.new

s.get "/" do |r|
  [200, { "Content-Type" => "text/plain"}, ["root"]]
end

s.get "/something" do |r|
  [200, { "Content-Type" => "text/plain"}, ["something"]]
end

s.get "/something/this" do |r|
  [200, { "Content-Type" => "text/plain"}, ["something this"]]
end

s.map "/food", Food.new

s.start 2000