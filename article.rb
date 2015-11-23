require 'mechanize'
require 'paperclip'
require 'mailgun'
require_relative './article_mailer'

WP_URL = "https://en.wikipedia.org"
DELETE_LOG = "w/index.php?title=Special%3ALog&type=delete&page="

class Article < ActiveRecord::Base
  include Paperclip::Glue
  validates_uniqueness_of :title
  has_attached_file :page,
    :storage => :s3,
    :path => "wikipedia/#{ENV["ENVIRONMENT"] != "production" ? 'testing/' : ''}articles/:id/:filename",
  :s3_region => 'us-east-1',
    :s3_credentials => Proc.new{|a| a.instance.s3_credentials }
  validates_attachment_content_type :page, content_type: /\Atext\/.*\Z/

  def self.update_or_create(title)
    article = find_by(title: title)
    if article
      article.update_attributes(last_seen: Time.now)
    else
      article = Article.create(
        title: title,
        last_seen: Time.now,
      )
    end
    article
  end

  def self.archive_pages
    where(archived: false).each_with_index do | article, index |
      puts "Archiving article ##{index}"
      article.archive
    end
  end

  def self.check_all_for_deletions
    where(deleted: false).each_with_index do | article, index |
      puts "Checking for deletion ##{index}"
      article.check_for_deletion
    end
  end

  def self.deleted_today
    where('deleted_at >= ?', 1.day.ago)
  end

  def self.daily_digest
    ArticleMailer.mail(deleted_today)
  end

  def archive
    www = mechanize.get("#{WP_URL}/wiki/#{title.gsub(' ', '_')}")
    filename = "tmp/#{title.gsub(' ', '_')}.html"
    www.save_as(filename)
    file = File.open(filename, 'r')
    begin
      self.page = file
      if save
        self.archived = true
        save
      else
        puts "didn't work"
      end
    rescue
      puts "didn't work"
    end
  end

  def mechanize
    Mechanize.new
  end

  def check_for_deletion
    url = "#{WP_URL}/#{DELETE_LOG}#{title}"
    www = mechanize.get(url)
    result = www.link_with(:text => "Wikipedia:Articles for deletion/#{title}")
    if result
      deleted = www.link_with(text: title).attributes
      .attributes["href"].value.index('redlink=1') != nil
      if deleted
        puts "Deleted #{title}!"
        update_attributes(
          deleted: true,
          on_list: false,
          deleted_at: Time.now
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
