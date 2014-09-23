# coding: utf-8

module LodViewRewrite
  class Utility
    def self.set_response_format( id )
      case id
      when :js || 'js'
        'application/json'
      when :tsv || 'tsv'
        'text/tab-separated-values'
      when :csv || 'csv'
        'text/csv'
      else
        'application/json'
      end
    end
  end
end
