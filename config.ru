$:.unshift( File.dirname( __FILE__ ) )

use AppMetric

require './index'
run Sinatra::Application
