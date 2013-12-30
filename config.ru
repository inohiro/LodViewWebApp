$:.unshift( File.dirname( __FILE__ ) )

require './index'
run Sinatra::Application
