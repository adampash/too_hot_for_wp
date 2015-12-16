require 'mechanize'
require_relative './app'

URL = "https://en.wikipedia.org"
class WikiScrape
  attr_accessor :next
  def initialize
    @next = false
  end

  def mechanize
    Mechanize.new
  end

  def fetch_page
    @next = @next || "/wiki/Category:Articles_for_deletion"
    url = "#{URL}#{@next}"
    puts url
    page = mechanize.get(url)
    begin
      @next = page.link_with(:text => 'next page').attributes
                .attributes["href"].value
      puts @next
    rescue
      @next = nil
    end

    articles = page.at('#mw-pages').search('li a')
    articles
  end

  def fetch_and_save_all_articles
    page = 0
    article_count = 0
    until @next.nil?
      begin
        puts "Fetching page #{page += 1}"
        articles = fetch_page
        articles.each do |article|
          puts "    Saving article #{article_count += 1}"
          extract_article(article)
        end
      rescue Exception => e
        puts e.message
      end
    end
  end

  def extract_article(article)
    title = article.attributes["title"].value
    Article.update_or_create(title)
  end
end
