require "xml"
require "halite" # has follow-redirects ability, std lib http doesn't.
require "option_parser"
require "term-spinner"

class Pododger
  property :feed_url, :out_dir

  @feed_url = String
  @out_dir = String # should this be <String?> or <String> if user doesn't pass in -d to change out_dir ... I don't know.
  @mp3s = [] of Hash(String, String)

  def initialize
    @out_dir = nil # shouldn't this make
    @feed_url = "" # should be nilable?
  end

  def download
    get_mp3s_from_xml
    @mp3s.each { |mp3| save_file(mp3) } unless @mp3s.nil?
  end

  def out_dir=(f : String)
    @out_dir = f
  end

  def save_file(mp3)
    spinner = Term::Spinner.new("[:spinner] Fetching: #{mp3["title"][(0..64)]} ...", format: :dots)
    spinner.auto_spin
    cleaned_title = mp3["title"].gsub("/", "-") # replace problem chars.
    resp = Halite.follow.get("#{mp3["url"]}")

    if @out_dir
      file_path = "#{@out_dir}/#{cleaned_title}.mp3"
    else
      file_path = "#{cleaned_title}.mp3"
    end

    File.write(file_path, resp.body)
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

  parser.on("-d", "--dir string", "Directory to save files to.") do |dir|
    if Dir.exists?(dir) == false
      puts "Directory: #{dir} does not exist. Exiting."
      exit
    end
    pod.out_dir = dir
  end

  parser.on("-h", "--help", "Show this help") { puts parser; exit }
  parser.separator

  # Parser Error Handling

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end

  if ARGV.empty?
    puts parser
    exit
  end

  # if the first ARGV isn't one of the valid commans, throw an error.
  if ARGV.empty? || !["-f", "-h", "-d", "--feed", "--help", "--dir"].includes? ARGV.first
    STDERR.puts "ERROR: '#{ARGV.first}' is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

pod.download
