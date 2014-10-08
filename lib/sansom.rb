#!/usr/bin/env ruby

require_relative "./sansom/sansomable"

Sansom = Class.new Object
Sansom.send :include, Sansomable
