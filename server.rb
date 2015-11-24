require 'sinatra'
require_relative './app'

get '/wiki/:title' do |title|
  article = Article.find_by(title: title.gsub('_', ' '))
  article.to_html
end
