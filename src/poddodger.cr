require "xml"
require "halite" # has follow-redirects ability, std lib http doesn't.
require "option_parser"
require "term-spinner"

def get_xml_from_url(url)
  puts "Fetching feed..."
  response = Halite.get(url)
  response.body
end

def save_file(mp3)
  spinner = Term::Spinner.new("[:spinner] Fetching: #{mp3["title"][(0..64)]} ...", format: :pulse_2)
  spinner.auto_spin
  cleaned_title = mp3["title"].gsub("/", "-") # replace problem chars.
  resp = Halite.follow.get("#{mp3["url"]}")
  File.write("#{cleaned_title}.mp3", resp.body)
  spinner.success("Done!")
end

def get_mp3s_from_xml(xml)
  fc = xml.first_element_child
  out = [] of Hash(String, String)

  # this is messy, could be recursive + use .next_sibling?
  if fc
    fc.children.each do |child|
      if child.name == "channel"
        items = child.children.select { |c| c.name == "item" }
        items.each do |item|
          enclosure = item.children.find { |f| f.name == "enclosure" }
          title = item.children.find { |f| f.name == "title" }.try &.content
          url = enclosure["url"] unless enclosure.nil?
          out << {"title" => title, "url" => url} unless title.nil? || url.nil?
        end
      end
    end
  end
  out
end

def do_all(url)
  xml = get_xml_from_url(url)
  mp3s = get_mp3s_from_xml(XML.parse(xml))
  mp3s.each do |mp3|
    save_file(mp3) unless mp3s.nil?
  end
  mp3s.each { |mp3| save_file(mp3) } unless mp3s.nil?
end

module Poddodger
  VERSION = "0.1.0"
  feed = ""
  xml = ""

  p = OptionParser.parse() do |parser|
    puts ""
    parser.banner = "Usage: poddodger [arguments]"
    parser.separator
    parser.on("-f FEED", "--feed=FEED", "URL of podcast rss feed") { |url| do_all(url) }
    parser.on("-h", "--help", "Show this help") { puts parser; exit 0 }
    parser.separator
  end

  if ARGV.empty?
    puts p; exit 0
  end
end
