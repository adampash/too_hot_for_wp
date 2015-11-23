require 'active_record'
require 'sqlite3'
require 'logger'
require 'mechanize'

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])
DELETE_LOG = "https://en.wikipedia.org/w/index.php?title=Special%3ALog&type=delete&page="

class Article < ActiveRecord::Base
  validates_uniqueness_of :title

  def self.check_all_for_deletions
    where(deleted: false).each_with_index do | article, index |
      puts "Checking article ##{index}"
      article.check_for_deletion
    end
  end

  def archive
    # TODO save to cloud
  end

  def check_for_deletion
    mechanize = Mechanize.new
    url = "#{DELETE_LOG}#{title}"
    page = mechanize.get(url)
    result = page.link_with(:text => "Wikipedia:Articles for deletion/#{title}")
    if result
      deleted = page.link_with(text: title).attributes
        .attributes["href"].value.index('redlink=1') != nil
      if deleted
        puts "Deleted #{title}!"
        update_attributes(
          deleted: true,
          on_list: false,
        )
      end
    end
  end
end
