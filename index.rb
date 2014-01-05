# coding: utf-8

require 'sinatra'
require 'sinatra/json'

require 'pp'
require 'json'

require 'LodViewRewrite'
require 'newrelic_rpm'

# require File.expand_path( "~/github/LodViewRewrite/lib/lod_view_rewrite.rb" )
# require LodViewRewrite

# require File.expand_path( "../lib/query.rb" )
# require File.expand_path( "../lib/filter.rb" )

=begin

=end

require 'uri'

get '/' do
  # Description of API
  'Hello, World'
end

get '/test/:id/' do
  view_id = params[:id]
  query = params["query"]
  begin
    json = JSON.parse( URI.decode query )
  rescue => ex
    puts ex
  end
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

get '/api/:view_id/' do
  condition = params[:condition]
  view_id = params[:view_id]

#   view = Viea.find_by_id view_id
#   query = Query.new( view )

#   filters = Filters.new( condition )
#   result = query.exec_sparql( filters )
#   return result
end

def get_view( view_id )
  queries = {
    1 => "SELECT * WHERE { ?subject <http://dbpedia.org/property/prefecture> <http://dbpedia.org/resource/Tokyo> . }",
  }

  # queries[view_id]

end

get '/api/fixed/1/' do
  view = test_view
  query = LodViewRewrite::Query.new( view )
  result = query.exec_sparql

  content_type 'application/json'
  result
end

get '/api/fixed/2/' do
  view = test_view
  query = LodViewRewrite::Query.new( view )
  cond = [
    {"Variable"=>"subject", "Condition"=>"http://dbpedia.org/resource/Minato,_Tokyo", "Operator"=>"=", "FilterType"=>'3',"ConditionType"=>"System.String"},
    {"Variable"=>"subject", "AggregationType"=>'3'} # count of ?subject
  ].to_json
  condition = LodViewRewrite::Condition.new( cond )

  result = query.exec_sparql( condition )

  content_type 'application/json'
  result
  # json( {:result => result}, :encoder => :to_json, :content_type => :js )
end

get '/api/fixed/3/' do
  view = test_view
  query = LodViewRewrite::Query.new( view )

  decoded = URI.decode( params['query'] )
  query_condition = decoded.to_json
  condition = LodViewRewrite::Condition.new( query_condition )

  require 'pp'
  puts '################################################'
  pp condition

  sparql = query.to_sparql( condition )
  puts "SPARQL: #{sparql}"

  result = query.exec_sparql( condition )
  content_type 'application/json'
  result
end

def test_view
  query =<<EOQ
SELECT *
WHERE {
  ?subject <http://dbpedia.org/property/prefecture> <http://dbpedia.org/resource/Tokyo> .
}
EOQ
  query
end
