require 'rubygems'
require 'nokogiri'
require 'open-uri'

EXDOI =  '10.1080/10615800801998914'

module Crossref
  class Metadata
    attr_accessor :doi, :crossref_url, :xml
    
    def initialize(doi, *opts)
      @doi = doi
      @crossref_url = "http://crossref.org/openurl/?noredirect=true&format=unixref&id=doi:" + doi
      @xml = Nokogiri::XML(open(@crossref_url))
    end

    def title
      self.xml.xpath('//titles/title').first.content
    end

    def authors
      first_author = self.xml.xpath('//person_name[@sequence="first"]').first

      authors = [hashify_name(first_author.children)]
      first_author.unlink
      
      # maybe we shouldn't delete the first author element, but change
      # the xpath below
      
      self.xml.xpath('//contributors/person_name[@contributor_role="author"]').each do |a| 
       authors << hashify_name(a.children) 
      end
      authors
    end
    
    def journal
      journal = Hash.new
      journal[:title] = self.xml.xpath('//journal/journal_metadata/full_title').first.content

      journal
    end
      
    
    private
  
    def hashify_name(element)
      n = Hash.new
      element.each do |e|
        n[e.name.to_sym] = e.content unless e.content.match(/\n/)
      end
      n
    end
    
  end
  
end
