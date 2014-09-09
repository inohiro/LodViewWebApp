# coding: utf-8

require_relative './lib/LodViewRewrite.rb'

require 'sinatra'
require 'sinatra/json'

require 'pp'
require 'json'

# require 'LodViewRewrite'
# require 'newrelic_rpm'

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

def exp2_view
  view =<<EOQ
PREFIX bsbm-inst: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/instances/>
PREFIX bsbm: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/vocabulary/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT *
WHERE {
 ?product rdfs:label ?label .
 ?product a bsbm-inst:ProductType55 .
 ?product bsbm:productPropertyNumeric1 ?value .
}
EOQ
  view
end

def exp1_view
  view =<<EOQ
PREFIX bsbm-inst: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/instances/>
PREFIX bsbm: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/vocabulary/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT *
WHERE {
 ?product rdfs:label ?label .
 ?product a bsbm-inst:ProductType100 .
 ?product bsbm:productPropertyNumeric1 ?value .
}
EOQ
  view
end

def exp3_view
  view=<<EOQ
PREFIX bsbm-inst: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/instances/>
PREFIX bsbm: <http://www4.wiwiss.fu-berlin.de/bizer/bsbm/v01/vocabulary/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT AVG(?value) AS ?avgvalue
WHERE {
 ?product rdfs:label ?label .
 ?product a bsbm-inst:ProductType100 .
 ?product bsbm:productPropertyNumeric1 ?value .
 FILTER (?value <= 400 )
}
LIMIT 1000
EOQ

  view
end

def dbpedia_view1
  view =<<EOQ
PREFIX dbpedia-owl: <http://dbpedia.org/ontology/>

select *
where {
  ?subject dbpedia-owl:leaderTitle ?object .
}
EOQ
  view
end

require 'pp'

get '/exp/1/' do
  cond = params[:query]

  view = dbpedia_view1
  query = LodViewRewrite::Query.new( view )
  condition = LodViewRewrite::Condition.new( cond )

  query.exec_sparql( condition )
end

get '/exp/2/' do
  cond = params[:query]

  3.times { puts "" }
  pp cond
  3.times { puts "" }

  view = exp2_view
  query = LodViewRewrite::Query.new( view )
  condition = LodViewRewrite::Condition.new( cond )

  result = query.exec_sparql( condition )
  result
end

get '/api/fixed/1/' do
  view = test_view
  query = LodViewRewrite::Query.new( view )
  result = query.exec_sparql

  # content_type 'application/json'
  # result.gsub( /\s+/, "")
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

  # content_type 'application/json'
  result
  # result.gsub( /\s+/, "")
  # json( {:result => result}, :encoder => :to_json, :content_type => :js )
end

get '/api/fixed/3/' do
  view = test_view
  query = LodViewRewrite::Query.new( view, :tsv, 1000 )
  decoded = URI.decode( params['query'] )

  puts '--------------------------------------------------------------'
  puts decoded


  condition = LodViewRewrite::Condition.new( decoded, :tsv )


  require 'pp'

  3.times { puts "" }
  pp condition
  puts ""
  sparql = query.to_sparql( condition )
  puts sparql
  3.times { puts "" }

  "HELLO"

  # result = query.exec_sparql( condition )
  # result = query.exec_sparql
  # content_type 'application/json'
  # result.gsub( /\s+/, "")
  # result
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
