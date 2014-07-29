#!/usr/bin/env ruby

require "./sansom"

class Mixin < Hash
  include Sansomable
  
  def template
    get "/sansomable" do |r|
      [200, { "Content-Type" => "text/plain"}, ["Sansomable Hash"]]
    end
  end
end

s = Sansom.new

s.get "/" do |r| 
  [200, { "Content-Type" => "text/plain"}, ["root"]] 
end

s.map "/mixins", Mixin.new
s.start 3002
