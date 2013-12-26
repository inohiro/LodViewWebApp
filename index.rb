require 'sinatra'

require File.expand_path( "~/github/LodViewRewrite/lib/lod_view_rewrite.rb" )
# require LodViewRewrite

get '/' do
  # Description of API
  'Hello, World'
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

get '/api/:view_id' do
  condition = params[:condition]
  view_id = params[:view_id]

  view = Viea.find_by_id view_id
  query = Query.new( view )

  filters = Filters.new( condition )
  result = query.exec_sparql( filters )
  return result
end
