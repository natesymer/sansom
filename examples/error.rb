#!/usr/bin/env ruby

require_relative "../lib/sansom" rescue require "sansom"

TestError = Class.new StandardError

s = Sansom.new

s.error TestError do |error, r|
  [500, {}, [error.message]]
end

s.get "/" do |r|
  raise TestError, "This is the message being tripped."
  [200, {}, ["Should never happen"]]
end

s.start 2000