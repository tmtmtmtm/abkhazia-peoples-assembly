#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//div[@class="news-list"]//td[.//h2]').each do |td|
    person_link = td.xpath('.//a[h2]/@href').text
    data = { 
      id: person_link[/ELEMENT_ID=(\d+)/, 1],
      name: td.css('h2').text.tidy,
      source: person_link,
      area: td.text[/Округ №\s*(\d+)/, 1],
      email: td.xpath('.//small[contains(.,"почта")]').text.tidy.split(/:\s*/, 2).last,
      image: td.parent.css('img.preview_picture/@src').text,
      term: 5
    }
    %i(image source).each { |i| data[i] = URI.join(url, URI.escape(data[i])).to_s unless data[i].to_s.empty? }
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

scrape_list('http://www.parlamentra.org/rus/officials/index.php')
