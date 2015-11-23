require 'mechanize'
require 'paperclip'

DELETE_LOG = "https://en.wikipedia.org/w/index.php?title=Special%3ALog&type=delete&page="

class Article < ActiveRecord::Base
  include Paperclip::Glue
  validates_uniqueness_of :title
  has_attached_file :page,
    :storage => :s3,
    :path => 'wikipedia/artciles/:id/:filename',
    :s3_region => 'us-east-1',
    :s3_credentials => Proc.new{|a| a.instance.s3_credentials }
  validates_attachment_content_type :page, content_type: /\Atext\/.*\Z/


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

  def s3_credentials
    {
      :bucket => ENV["AWS_BUCKET"],
      :access_key_id => ENV["AWS_ACCESS_KEY"],
      :secret_access_key => ENV["AWS_SECRET_KEY"],
    }
  end
end
