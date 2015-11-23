require 'mailgun'

module ArticleMailer
  def self.mail(articles)
    mg_client = Mailgun::Client.new ENV["MAILGUN_API_KEY"]
    message_params = {
      :from    => 'labs@gawker.com',
      :to      => 'pash@gawker.com, ashley@gawker.com',
      :subject => "#{articles.count} deletions today",
      :html    => build_text(articles)
    }
    mg_client.send_message(ENV["MAILGUN_DOMAIN"], message_params)
    # mg_client.send_message "app185bded172554a3a936cde24416d7ed6.mailgun.org", message_params
  end

  def self.build_text(articles)
    articles.reduce('') do |acc, article|
      acc += "
        <p>
          <b><a href=\"#{article.page.url}\">#{article.title}</a></b>
          [<a href=\"https://en.wikipedia.org/wiki/Wikipedia:Articles_for_deletion/#{article.title.gsub(' ', '_')}\">Discussion</a>]
      "
      acc
    end
  end
end
