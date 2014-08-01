#!/usr/bin/env ruby

require "rack"

module Rack
  class Fastlint
    LintError = Class.new StandardError
    def self.response res
      return false unless res.kind_of?(Array) && res.count == 3
      
      status, headers, body = res

      return false unless status.to_i >= 100 || status.to_i == -1
      return false unless headers.respond_to? :each
      return false unless body.respond_to? :each
      
      if body.respond_to? :to_path
        return false unless File.exist? body.to_path
      end
      
      begin
        headers.each { |k,v|
          next if key =~ /^rack\..+$/
          throw LintError unless k.kind_of? String
          throw LintError unless v.kind_of? String
          throw LintError if k.downcase == "status"
          throw LintError unless k !~ /[:\n]/
          throw LintError unless k !~ /[-_]\z/
          throw LintError unless k =~ /\A[a-zA-Z][a-zA-Z0-9_-]*\z/
        }
      
        body.each { |part| throw LintError unless part.kind_of? String }
      rescue StandardError
        return false
      end

      true
    end
  end
end