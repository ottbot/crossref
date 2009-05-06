require 'rubygems'
require 'nokogiri'
require 'open-uri'

module Crossref
  class Metadata
    attr_accessor :doi, :url, :xml
    
    def initialize(opts = {})
      @base_url =  opts[:base_url] || 'http://crossref.org/openurl/?noredirect=true&format=unixref'      
      @doi = opts[:doi]
      @pid = opts[:pid]
      @base_url += '&pid=' + @pid if @pid
      
      if @doi
        @url = @base_url + "&id=doi:" + @doi
        @xml = get_xml(@url)
      end
    end
    
    def doi(doi)
      Crossref::Metadata.new(:doi => doi, :pid => @pid, :url => @base_url)
    end
    
    def title
      xpath_first('//titles/title')
    end

    def authors
      first_author = self.xml.xpath('//person_name[@sequence="first"]').first

      authors = [hashify_name(first_author.children)]
      first_author.unlink
      
      # maybe we shouldn't delete the first author element, but change
      # the xpath below to exlude it
      self.xml.xpath('//contributors/person_name[@contributor_role="author"]').each do |a| 
       authors << hashify_name(a.children) 
      end
      authors
    end

    def published
      pub = Hash.new
      pub[:year] = self.xml.xpath('//publication_date/year')
      pub[:month] = self.xml.xpath('//publication_date/month')
      pub
    end
    
    def journal
      journal = Hash.new
      journal[:title] = xpath_first('//journal_metadata/full_title')
      journal[:title] = xpath_first('//journal_metadata/abbrev_title')
      journal[:volume] = xpath_first('//journal_issue/journal_volume/volume') 
      journal[:issue] = xpath_first('//journal_issue/issue')
      journal[:first_page] = xpath_first('//first_page')
      journal[:last_page] = xpath_first('//last_page')
      journal[:issn] = xpath_first('//journal_metadata/issn')
      journal
    end

    def resource
      xpath_first('//doi_data/resource')
    end
    
    #------------------------------------------------------
    private

    def xpath_first(q)
      self.xml.xpath(q).first.content
    end
    
    def get_xml(url)
      Nokogiri::XML(open(url))
    end
    
    def hashify_name(element)
      n = Hash.new
      element.each do |e|
        n[e.name.to_sym] = e.content unless e.content.match(/\n/)
      end
      n
    end
    
  end
  
end
