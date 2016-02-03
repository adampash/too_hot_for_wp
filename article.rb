require 'mechanize'
require 'slack-notifier'
require 'paperclip'
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
    article = find_by(title: sanitize(title))
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

  def sanitize(title="oh \"hi\" it's me/you")
    title.gsub(/['"\/]/, '')
  end

  def self.archive_pages
    where(archived: false).each_with_index do | article, index |
      begin
        puts "Archiving article ##{index}"
        article.archive
      rescue Exception => e
        puts e.message
      end
    end
  end

  def self.not_deleted
    where(deleted: false)
  end

  def self.still_listed
    where('last_seen >= ?', 2.days.ago)
  end

  def self.check_all_for_deletions
    not_deleted.still_listed.each_with_index do | article, index |
    # where(deleted: false).each_with_index do | article, index |
      begin
        puts "Checking for deletion ##{index}"
        article.check_for_deletion
      rescue Exception => e
        puts e.message
      end
    end
  end

  def self.deleted_today
    where('deleted_at >= ?', 1.day.ago)
  end

  def self.daily_digest
    ArticleMailer.mail(deleted_today)
  end

  def archive
    www = mechanize.get("#{WP_URL}/wiki/#{title_score}")
    filename = "tmp/#{title_score}.html"
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
    rescue Exception => e
      puts "didn't work"
      p e.message
      p e.backtrace.inspect
    end
  end

  def mechanize
    Mechanize.new
  end

  def delete_log_url
    "#{WP_URL}/#{DELETE_LOG}#{title}"
  end

  def check_for_deletion
    www = mechanize.get(delete_log_url)
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
        notify
      else
        puts "Still up #{title}"
      end
    else
      puts "No result"
    end
  end

  def notify
    icon = %w(
      :death:
      :cry:
      :bomb:
      :boom:
    )
    Slack::Notifier.new(
      ENV["SLACK_WEBHOOK_URL"],
      channel: "too-hot-for-wp",
      username: "WikiBot",
      icon_emoji: ':wikipedia:',
    ).ping("#{icon.sample} <a href=\"#{page_url}\">#{title}</a> #{icon.sample}")
  end

  def to_html
    doc = Nokogiri::HTML(open(page.url))
    links = doc.css('a, link')
    links.map do | link |
      href = link.attributes["href"]
      if href
        url = href.value.gsub(/(^\/\w)/, WP_URL + '\1')
        link["href"] = url
      end
    end
    src = doc.css('img, script')
    src.map do | link |
      src = link.attributes["src"]
      if src
        url = src.value.gsub(/(^\/\w)/, WP_URL + '\1')
        link["src"] = url
      end
    end
    doc.to_html
  end

  def page_url
    "#{ENV["BASE_URL"]}/wiki/#{title_score}"
  end

  def title_score
    title.gsub(' ', '_')
  end

  def s3_credentials
    {
      :bucket => ENV["AWS_BUCKET"],
      :access_key_id => ENV["AWS_ACCESS_KEY"],
      :secret_access_key => ENV["AWS_SECRET_KEY"],
    }
  end
end
