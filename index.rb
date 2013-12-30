# coding: utf-8

require 'sinatra'
require 'pp'
require 'json'

require 'newrelic_rpm'

# require File.expand_path( "~/github/LodViewRewrite/lib/lod_view_rewrite.rb" )
# require LodViewRewrite

# require File.expand_path( "../lib/query.rb" )
# require File.expand_path( "../lib/filter.rb" )

require 'uri'

get '/' do
  # Description of API
  'Hello, World'
end

get '/test/:id/' do
  view_id = params[:id]
  query = params["query"]
  json = JSON.parse( URI.decode query )

  # filters = LodViewRewrite::Filters.new( query ).to_a

  "view_id: #{view_id}, query: #{json}"
end

get '/views' do
  # return all views
end

get '/views/:id' do
  id = params[:id]
end

put '/views/:id' do
  id = params[:id]
end

post '/views' do
  # create a new View
end

# API as LINQ Entrypoint

# get '/api/:view_id' do
#   condition = params[:condition]
#   view_id = params[:view_id]

#   view = Viea.find_by_id view_id
#   query = Query.new( view )

#   filters = Filters.new( condition )
#   result = query.exec_sparql( filters )
#   return result
# end
