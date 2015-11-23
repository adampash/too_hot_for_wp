module ArticleMailer
  def self.mail(articles)
    mg_client = Mailgun::Client.new ENV["MAILGUN_API_KEY"]
    message_params = {
      :from    => 'labs@gawker.com',
      :to      => 'pash@gawker.com, ashley@gawker.com',
      :subject => "#{articles.count} deletions today",
      :text    => build_text(articles)
    }
    mg_client.send_message ENV["MAILGUN_DOMAIN"], message_params
  end

  def self.build_text(articles)
    articles.reduce('') do |acc, article|
      acc += "
        <h4><a href=\"#{article.page.url}\">#{article.title}</a></h4>
        <p>
          <a href=\"https://en.wikipedia.org/wiki/Wikipedia:Articles_for_deletion/#{article.title.gsub(' ', '_')}\">Discussion</a>
        </p>
      "
      acc
    end
  end
end
