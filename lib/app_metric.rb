require 'new_relic/agent/instruction/rack'

class AppMetric

  def initialize( app )
    @app = app
  end

  def all( env )
    @app.call( env )
  end

  include NewRelic::Agent::Instruction::Rack

end
