require "xml"
require "halite" # has follow-redirects ability, std lib http doesn't.
require "option_parser"
require "term-spinner"

class Pododger
  property :feed_url, :out_dir

  @feed_url = String
  @out_dir = String
  @mp3s = [] of Hash(String, String)

  def intialize
    @out_dir = ""  # should mark this as possibly nil: string?
    @feed_url = "" # ditto
  end

  def download
    get_mp3s_from_xml
    @mp3s.each { |mp3| save_file(mp3) } unless @mp3s.nil?
  end

  def save_file(mp3)
    spinner = Term::Spinner.new("[:spinner] Fetching: #{mp3["title"][(0..64)]} ...", format: :dots)
    spinner.auto_spin
    cleaned_title = mp3["title"].gsub("/", "-") # replace problem chars.
    resp = Halite.follow.get("#{mp3["url"]}")
    File.write("#{cleaned_title}.mp3", resp.body)
    spinner.success("Done!")
  end

  def get_mp3s_from_xml
    puts "Fetching feed... #{@feed_url}"
    response = Halite.get(@feed_url.to_s) # feed_url is a (String | String.class) - why? Why do I have to do .to_s?
    xml = XML.parse(response.body)
    fc = xml.first_element_child

    # this is messy, could be recursive + use .next_sibling?
    if fc
      fc.children.each do |child|
        if child.name == "channel"
          items = child.children.select { |c| c.name == "item" }
          items.each do |item|
            enclosure = item.children.find { |f| f.name == "enclosure" }
            title = item.children.find { |f| f.name == "title" }.try &.content
            url = enclosure["url"] unless enclosure.nil?
            @mp3s << {"title" => title, "url" => url} unless title.nil? || url.nil?
          end
        end
      end
    end
  end
end

pod = Pododger.new

OptionParser.parse() do |parser|
  parser.banner = "Usage: poddodger [arguments]"
  parser.separator

  parser.on("-f", "--feed string", "URL of podcast rss feed") { |u| pod.feed_url = u }
  parser.on("-d", "--dir string", "Directory to save files to.") { |d| pod.out_dir = d }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }

  parser.missing_option do |x|
    puts "x #{x}"
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end

  parser.separator

  # if the first ARGV isn't one of the valid commans, throw an error.
  if ARGV.empty? || !["-f", "-h", "-d", "--feed", "--help", "--dir"].includes? ARGV.first
    STDERR.puts "ERROR: '#{ARGV.first}' is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

pod.download
