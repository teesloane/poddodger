require "xml"
require "halite" # has follow-redirects ability, std lib http doesn't.
require "option_parser"
require "term-spinner"

class Pododger
  property :feed_url, :out_dir, :overwrite
  getter :num_downloaded

  @feed_url = String
  @out_dir = String # should this be <String?> or <String> if user doesn't pass in -d to change out_dir ... I don't know.
  @overwrite = Bool
  @mp3s = [] of Hash(String, String)
  @num_downloaded = Int16

  def initialize
    @out_dir = nil
    @feed_url = "" # should be nilable?
    @overwrite = false
    @num_downloaded = 0
  end

  def download
    get_mp3s_from_xml
    @mp3s.each { |mp3| save_file(mp3) } unless @mp3s.nil?
  end

  def out_dir=(f : String)
    @out_dir = f
  end

  def save_file(mp3)
    file_name = mp3["title"].gsub("/", "-") # replace problem chars.

    if @out_dir
      file_path = "#{@out_dir}/#{file_name}.mp3"
    else
      file_path = "#{file_name}.mp3"
    end

    if File.exists?(file_path) && !@overwrite
      puts "File: #{file_name[(0..32)]}... already exists. Use '-o' flag to overwrite.."
      return
    end

    spinner = Term::Spinner.new("[:spinner] Fetching: #{file_name[(0..64)]} ...", format: :dots)
    spinner.auto_spin
    resp = Halite.follow.get("#{mp3["url"]}")
    File.write(file_path, resp.body)

    spinner.success("Done!")
  end

  def inc_num_downloaded
    @num_downloaded += 1
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

def parser_err(parser, err)
  STDERR.puts "ERROR: #{err}"
  STDERR.puts parser
  exit(1)
end

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

  parser.on("-o", "--overwrite", "Overwrite existing files") { pod.overwrite = true }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }

  parser.separator

  parser.invalid_option { |flag| parser_err(parser, "#{flag} is not a valid flag.") }
  parser.missing_option { |flag| parser_err(parser, "#{flag} is missing an option") }

  if ARGV.empty?
    puts parser
    exit
  end

  # if the first ARGV isn't one of the valid commans, throw an error.
  if !["-f", "-h", "-d", "--feed", "--help", "--dir"].includes? ARGV.first
    parser_err(parser, "#{ARGV.first} is not a valid option.")
  end
end

pod.download

puts "\nDownloaded #{pod.num_downloaded} podcast episodes."
