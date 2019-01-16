require 'curb'
require 'nokogiri'
require 'csv'
require 'xpath'
require 'uri'
require 'open-uri'

class Multiproduct
  attr_accessor :title, :price, :image

  def initialize (title, price, image)
    @title = title
    @price = price
    @image = image
  end
end

class Parser
  attr_accessor :url_to_parse
  attr_reader :multiproducts

  public

  def initialize (url_to_parse)
    @multiproducts = []
    @url_to_parse = url_to_parse
  end

  def parse_html()
    #GET parameter
    page_counter = 0

    #to start main cycle
    previous_html = "not"
    html = "equal"

    while previous_html != html
      uri = URI.parse(url_to_parse)
      params = {:p => page_counter}

      uri.query = URI.encode_www_form(params)

      #in order to check have we reached the last page or not
      previous_html = html
      html = get_html(uri)


      multiproduct_list_html = Nokogiri::HTML(html).xpath('//*[@id="product_list"]/li').each do |product|
        multiproduct_url = product.at_css('div div a')['href']
        puts("Parsing " + multiproduct_url + " ..")

        multiproduct_full_html = get_html(multiproduct_url)
        multiproduct_element_html = Nokogiri::HTML(multiproduct_full_html).xpath(
            '//*[@id="center_column"]/div/div/div[1]/div[1]/p')

        title = multiproduct_element_html.at_xpath(
            '//*[@id="center_column"]/div/div/div[1]/div[1]/p').text.delete!("\n").strip

        image = multiproduct_element_html.at_xpath(
            '//*[@id="bigpic"]')['src']

        multiproduct_element_html.xpath('//*[@id="attributes"]/fieldset/div/ul/li').each do |product_by_weight|
          weight = product_by_weight.at_css('label span[1]')
          price = product_by_weight.at_css('label span[2]')
          title_to_push = title + " - " + weight

          #pushing Multiproduct object here
          @multiproducts.push(Multiproduct.new(title_to_push, price, image))
        end
      end

      #next page
      page_counter += 1
    end

    return @multiproducts
  end

  private

  def get_html(url_or_uri)
    http = Curl.get(url_or_uri)
    return http.body_str
  end

end

if ARGV.length < 2
  puts "Too few arguments"
  puts "format: script_name url_to_parse output_filename"
  exit
end


url_to_parse = ARGV[0]
output_name = ARGV[1]

puts("base url: " + url_to_parse)
puts("output file: " + output_name )

parser = Parser.new(url_to_parse)
multiproducts = parser.parse_html()


#first row (title)
CSV.open(output_name.chomp + ".csv", "a+") do |csv|
  csv << ["Name", "Price",
          "Image"]
end


parser.multiproducts.each_with_index do |write, counter|
  CSV.open(output_name.chomp + ".csv", "a+") do |csv|
    csv << [multiproducts[counter].title, multiproducts[counter].price,
            multiproducts[counter].image]
  end
end

puts("done.")