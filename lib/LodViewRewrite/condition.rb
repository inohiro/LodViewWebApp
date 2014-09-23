# coding: utf-8

module LodViewRewrite
  class Condition

    attr_reader :select, :filters, :orderby, :groupby_affected_conditions, :groupby
    attr_writer :groupby_affected_conditions

    def initialize( json = '', response_format = :js )
      unless json == ''
        @json = json
        @conditions = nil
        @filters = []
        @select = ''
        @orderby = { 'Enable'=>false, 'Type'=> 0, 'Variable'=>'', 'Method'=>'' } # type: { 1: OrderBy, 2: OrderByDescending }
        @groupby_affected_conditions = []
        @groupby = { 'Enable'=>false, 'Variable'=>'', 'Having'=> {} }
        @response_format = Utility.set_response_format( response_format )
        parse
      end
    end

    def parse
      @conditions = JSON.load( @json ) || []
      build_conditions
    end

    # Condition format:
    #   conditions are noted as a Array
    #   conditions includes a few hash elements
    #   conditions are constructed by Selection, Filter, Aggregation
    #
    # FilterType:
    #   (0: Regex, 1: Exists, 2: NotExists,) 3: Normal
    #
    # SelectionType:
    #   0: Single, 1: Multiple, 2: All
    #
    # Selection:
    #  ex1) [{"Left"=>"names", "Right"=>"inohiro", "Operator"=>"=", "FilterType"=>3}]
    #  ex2) [{"FilterType"=>6}]
    #    => "SELECT * WHERE { ..."
    #
    #  ex3) [{"Variable"=>"name", "Condition"=>"", "Operator"=>"", "FilterType"=>4}]
    #    => "SELECT ?name WHERE { ..."
    #
    #  ex4) [{"FilterType"=>5, "Variables"=>[
    #          {"Variable"=>"name", "Condition"=>"", "Operator"=>"", "FilterType"=>4},
    #          {"Variable"=>"age", "Condition"=>"", "Operator"=>"", "FilterType"=>4}]},
    #        {"Left"=>"age", "Right"=>"30", "Operator"=>"<=", "FilterType"=>3}]
    #   => "SELECT ?name ?age WHERE { ... FILTER( ?age <= 30 ) }"
    #
    # Aggregation:
    #
    # AggregationType:
    #   0: Min, 1: Max, 2: Sum, 3: Count, 4: Average, 5: GroupBy,
    #   6: OrderBy, 7: OrderByDescending
    #
    #  ex1) [{"Variable"=>"age", "AggregationType"=>1}]
    #    => "SELECT (MIN(?age) AS ?min_age WHERE { ..."
    #
    #  ex2) [{"Left"=>"name", "Right"=>"inohiro", "Operator"=>"=", "FilterType"=>3},
    #        {"Variable"=>"age", "AggregationType"=>4}]
    #    => "SELECT (AVG(?age) AS ?avg_age) WHERE { ... FILTER( ?name, "inohiro" ) }"
    #
    #  If conditions contain 'GroupBy (5)', the last condition will be GroupBy condition,
    #  the first condition of conditions will be 'Having' condition of GroupBy.
    #

    def build_filter_from_condition( condition )
      filter = "FILTER "

      case condition['FilterType']
      when 0
        # build_regex_filter( condition )
        filter << "regex ( #{hatenize( condition['var'] )}, \"#{condition['condition']}\""
        filter << ", \"#{condition['flag']}\"" if condition['flag']
        filter << " )"
      when 1
        filter << "EXISTS { #{condition['subject']} #{condition['predicate']} #{condition['object']} }"
      when 2
        filter << "NOT EXISTS { #{condition['subject']} #{condition['predicate']} #{condition['object']} }"
      when 3
        if condition['ConditionType'] == "System.String"
          filter << "(str(#{hatenize( condition['Variable'] )}) #{condition['Operator']} \"#{condition['Condition']}\")"
        elsif condition['ConditionType'] == "System.Int32" # integer
          filter << "(#{hatenize( condition['Variable'] )} #{condition['Operator']} #{condition['Condition']})"
        else
          raise UnknownConditionDataType
        end
      else
        raise UnknownFilterConditionType
      end
      filter
    end

    def build_conditions( conditions = @conditions )

      if conditions.class == Array && conditions.size != 0
        unless detect_having_query
          conditions.each do |condition|
            if condition.key?( "FilterType" )
              @filters << build_filter_from_condition( condition )
            elsif condition.key?( "SelectionType" )
              @select = build_select_closure_from_condition( condition )
            elsif condition.key?( "AggregationType" )
              @select = build_aggregation_from_condition( condition )
            end
          end
        end
      else
        # do nothing
      end
    end

    def detect_having_query
      last = @conditions.last

      if (last.key? 'AggregationType') && (last['AggregationType'] == 5)
        ### ORDER BY Condition ###
        @groupby['Enable'] = true
        @groupby['Variable'] = hatenize( last['Variable'] )

        ### HAVING Condition ###
        first = @conditions.first.dup
        @groupby['Having'] = first
        @groupby['Having']['Variable'] = hatenize( first['Variable'] )

        @conditions.pop
        @conditions.each {|condition| @groupby_affected_conditions << condition }
        # @groupby_affected_conditions.pop # delete last condition
        true
      else
        false
      end
    end

    def build_select_closure_from_condition( condition )
      select = "SELECT "

      case condition['SelectionType']
      when 0 # SingleSelection
        select << "#{hatenize(condition["Variable"])}"

        if condition['ConditionType'] == "System.String"
          @filters << "FILTER (str(#{hatenize( condition['Variable'] )}) #{condition['Operator']} \"#{condition['Condition']}\")"
        elsif condition['ConditionType'] == "System.Int32" # integer
          @filters << "FILTER (#{hatenize( condition['Variable'] )} #{condition['Operator']} #{condition['Condition']})"
        end
      when 1 # MultipleSelection
        condition["Variables"].each do |var|
          select << "#{hatenize( var["Variable"])} " if var["SelectionType"] == 0 # SingleSelection
        end
        select.strip!
      when 2 # All
        select << "*"
      else
        raise UnknownFilterConditionType
      end
      select # << "\n"
    end

    def build_aggregation_from_condition( condition )
      select = "SELECT "
      variable = condition["Variable"]

      # detect group by
      # it requires variable set

      case condition['AggregationType']
      when 0 # Min
        select << "(MIN(#{hatenize(variable)}) AS #{hatenize(variable, 'min_')})"
      when 1 # Max
        select << "(MAX(#{hatenize(variable)}) AS #{hatenize(variable, 'max_')})"
      when 2 # Sum
        select << "(SUM(#{hatenize(variable)}) AS #{hatenize(variable, 'sum_')})"
      when 3 # Count
        select << "(COUNT(#{hatenize(variable)}) AS #{hatenize(variable, 'count_')})"
      when 4 # Average
        select << "(AVG(#{hatenize(variable)}) AS #{hatenize(variable, 'avg_')})"
      when 5 # GroupBy (Having)
      when 6 # OrderBy
        select = ''
        @orderby['Enable'] = true
        @orderby['Type'] = 1 # OrderBy
        @orderby['Variable'] = hatenize( variable )
        @orderby['Method'] = condition['OrderByInnerMethod'].to_s if condition['OrderByInnerMethod']
      when 7 # OrderByDescending
        select = ''
        @orderby['Enable'] = true
        @orderby['Type'] = 2 # OrderByDescending
        @orderby['Variable'] = hatenize( variable )
        @orderby['Method'] = condition['OrderByInnerMethod'].to_s if condition['OrderByInnerMethod']
      else
        raise UnkwnownAggregationType
      end
      select.strip # << "\n"
    end

    def hatenize( variable, prefix = '' )
      if variable
        chars = variable.split( // )
        chars.unshift( prefix) if prefix != ''
        chars.unshift( '?' ) if chars.first != '?'
        chars.join
      else
        raise InvalidArgumentException
      end
    end

  end
end
