require 'rubygems'
require 'nokogiri'
require 'open-uri'

module Crossref
  VERSION = '0.0.3'

  class Metadata
    attr_accessor :doi, :url, :xml
    
    def initialize(opts = {})
      @base_url =  opts[:base_url] || 'http://crossref.org/openurl/?noredirect=true&format=unixref'      
      @doi = opts[:doi]
      @pid = opts[:pid]
      @base_url += '&pid=' + @pid if @pid
      
      if @doi
        @doi = sanitize_doi(@doi)
        @url = @base_url + "&id=doi:" + @doi
        @xml = get_xml(@url)
      end
    end

    
    def doi(doi)
      Crossref::Metadata.new(:doi => doi, :pid => @pid, :url => @base_url)
    end

    
    def result?
      if self.xml.nil? || self.xml.xpath('//error').size == 1
        false
      else
        self.xml.xpath('//doi_record').size == 1
      end
    end

    
    def title
      xpath_first('//titles/title')
    end
    
    
    def authors
      #first_author = self.xml.xpath('//person_name[@sequence="first"]').first
      #authors = [hashify_name(first_author.children)]
      #first_author.unlink

      authors = []
      self.xml.xpath('//contributors/person_name[@contributor_role="author"]').each do |a| 
       authors << hashify_nodes(a.children) 
      end
      authors
    end
    
    
    def published
      pub = Hash.new
      pub[:year] = xpath_first('//publication_date/year')
      pub[:month] = xpath_first('//publication_date/month')
      pub
    end

    
    def journal
      journal = hashify_nodes(self.xml.xpath('//journal_metadata').first.children)
      journal[:volume] = xpath_first('//journal_issue/journal_volume/volume') 
      journal[:issue] = xpath_first('//journal_issue/issue')
      journal[:first_page] = xpath_first('//first_page')
      journal[:last_page] = xpath_first('//last_page')

      journal
    end

    def resource
      xpath_first('//doi_data/resource')
    end
    
    #------------------------------------------------------
    private

    def xpath_first(q)
      if info = self.xml.xpath(q).first
        info.content
      else
        nil
      end
    end
    
    def get_xml(url)
      Nokogiri::XML(open(url))
    end
    
    def hashify_nodes(nodes)
      h = {}
      nodes.each do |node|
        h[node.name.to_sym] = node.content unless node.content.match(/\n/)
      end
      h
    end

    def sanitize_doi(doi)
      doi.gsub(/\n+|\s+/,'')
    end
    
  end
  
end
