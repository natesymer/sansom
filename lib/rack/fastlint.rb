#!/usr/bin/env ruby

require "rack"

module Rack
  class Fastlint
    def self.response res
      # Check response format
      return false unless res.kind_of?(Array) && res.count == 3
      
      status, headers, body = res

      return false unless status.to_i >= 100
      
      return false unless headers.respond_to? :each
      headers.each { |k,v|
        next if key =~ /^rack\..+$/
        return false unless k.kind_of? String
        return false unless v.kind_of? String
        return false if k.downcase == "status"
        return false unless k !~ /[:\n]/
        return false unless k !~ /[-_]\z/
        return false unless k =~ /\A[a-zA-Z][a-zA-Z0-9_-]*\z/
      }
      
      return false unless body.respond_to? :each
      body.each { |part| return false unless part.kind_of? String }
      
      if body.respond_to? :to_path
        return false unless File.exist? body.to_path
      end
      
      true
    end
  end
end