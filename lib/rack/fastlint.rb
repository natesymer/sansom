#!/usr/bin/env ruby

require "rack"

module Rack
  class Lint
    def self.fastlint res
      begin
        return false unless res.respond_to?(:to_a) && res.count == 3

        status, headers, body = res.to_a
        return false if status.nil?
        return false if headers.nil?
        return false if body.nil?

        return false unless status.to_i >= 100 || status.to_i == -1
        return false unless headers.respond_to? :each
        return false unless body.respond_to? :each
        return false if body.respond_to?(:to_path) && !File.exist?(body.to_path)
      
        if status.to_i < 200 || [204, 205, 304].include?(status.to_i)
          return false if headers.member? "Content-Length"
          return false if headers.member? "Content-Type"
        end
      
        headers.each { |k,v|
          next if k.start_with? "rack."
          return false unless k.kind_of? String
          return false unless v.kind_of? String
          return false if k == "Status"
          return false unless k !~ /[:\n]/
          return false unless k !~ /[-_]\z/
          return false unless k =~ /\A[a-zA-Z][a-zA-Z0-9_-]*\z/
        }
    
        body.each { |p| return false unless p.respond_to? :to_str } # to_str is implemented by classes that act like strigs
        true
      rescue => e
        false
      end
    end
  end
end