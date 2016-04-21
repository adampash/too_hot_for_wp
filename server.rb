require 'sinatra'
require 'sinatra/reloader'
require_relative './app'
require 'kaminari/sinatra'
register Kaminari::Helpers::SinatraHelpers


def development?
  ENV["ENVIRONMENT"] == 'development'
end
configure do
  set :server, :puma
  enable :reloader if development?
  also_reload '*.rb'
end

get '/wiki/:title*' do |title, rest|
  headers['Cache-Control'] = 'max-age=31536000' # one year
  full_title = title + rest
  article = Article.find_by(title: full_title.gsub('_', ' '))
  article.to_html
end

get '/' do
  page = params["page"] || 1
  @articles = Article.order(created_at: "DESC").page(page).per(50)
  erb :index, :layout => :layout
end
