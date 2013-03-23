require 'open-uri'

WIKIPEDIA_DOMAIN = 'http://en.wikipedia.org'

module Wikipedia

  module Filters
    def filter_links filters, links
      filtered_links = links
      if filters.include? :hash_tags
        filtered_links = self.filter_hash_tags filtered_links
      end

      if filters.include? :double_slashes
        filtered_links = self.filter_double_slashes filtered_links
      end

      if block_given?
        filtered_links = filtered_links.select do |url| 
          not yield(url)
        end
      end

      filtered_links
    end
    
    def filter_hash_tags links
      links.select{|url| not url.match(/\A#/)}
    end

    def filter_double_slashes links
      links.select{|url| not url.match(/\/\//)}
    end

  end

  class Page

    attr_accessor :heading, :abstract, :links

    extend Filters

    def initialize resource
      @resource = resource
    end

    def download
      url = "#{WIKIPEDIA_DOMAIN}/wiki/#{@resource}"
      @source = open(url).read
      self
    end

    def get_data
      @heading = get_heading(@source)
      @abstract = get_abstract(@source)
      @links = get_links(@source)
    end

    def get_heading source_html
      m = source_html.match(/<h1.*>(.+?)<\/h1>/im)
      m[1].gsub(/<\/?.+>/, "")
    end

    def get_abstract source_html
      m = source_html.match /\<\/table>\s+(<p>.+)<table.+?id="toc"/im
      m[1]
    end

    def get_links source_html
      source_html.scan(/<a.+?href="(.+?)"/im).flatten
    end

  end
end

# example ARGV: ["-r", "Ruby_on_Rails", "-s", "links"]
params = {}
args = ARGV.clone
while args.size != 0
  flag = args.shift.gsub(/\A-/,"")
  flag = flag.to_sym
 
  if args.size > 0 && !args.first.match(/\A-/)
    params[flag] = args.shift
  else
    params[flag] = nil
  end
end

if !params.include?(:r)
  puts %Q(Please provide resource name, i.e.: "Spacex", "V_for_vendetta")
  exit
end


wp = Wikipedia::Page.new params[:r]
wp.download.get_data

f_links = Wikipedia::Page.filter_links(
                [:hash_tags, :double_slashes], 
                wp.links
          ) { |url| url.match(/wiki\/.+:.+/) }
puts f_links
