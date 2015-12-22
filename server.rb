require 'sinatra'
require 'sinatra/reloader'
require_relative './app'

def development?
  ENV["ENVIRONMENT"] == 'development'
end
configure do
  set :server, :puma
  enable :reloader if development?
  also_reload '*.rb'
end

get '/wiki/:title' do |title|
  headers['Cache-Control'] = 'max-age=31536000' # one year
  article = Article.find_by(title: title.gsub('_', ' '))
  article.to_html
end
