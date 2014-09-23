# coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'sparql'
require 'net/http/persistent'

require 'LodViewRewrite/version.rb'
require 'LodViewRewrite/query.rb'
require 'LodViewRewrite/condition.rb'
require 'LodViewRewrite/utility.rb'

module LodViewRewrite
  # Your code goes here...
  class UnExpectedReturnCode; end
end
