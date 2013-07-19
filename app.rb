require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require

require 'sinatra'
set :protection, :except => :ip_spoofing

require 'sinatra/jsonp'
helpers Sinatra::Jsonp

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :domain => 'app.twinvite.us',
                           :secret => ENV['TWITTER_CONSUMER_KEY'] + ENV['TWITTER_CONSUMER_SECRET']

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
end

require 'rack-flash'

use Rack::Flash
#, :sweep => true

get '/login' do
  if session[:logged_in]
    redirect "/"
  else
    redirect to("/auth/twitter")
  end
end

get '/auth/twitter/callback' do
  if env['omniauth.auth']
    session[:logged_in] = true
    session[:uid] = env['omniauth.auth']['uid']
    session[:info] = env['omniauth.auth']['info']
    session[:credentials] = env['omniauth.auth']['credentials']
    flash[:notice] = "Welcome #{session[:info]['name']}!"
    redirect "/"
  else
    halt(401,'Not Authorized')
  end
end

get '/auth/failure' do
  params[:message]
end

get '/logout' do
  session[:logged_in] = false
  session[:uid] = nil
  session[:info] = nil
  session[:credentials] = nil
  redirect "http://twinvite.us"
end

get "/" do
  redirect "/login" unless session[:logged_in]
  erb :index, :locals => { :logged_in => session[:logged_in], :info => session[:info] }
end

    # content_type :json
    # env['omniauth.auth'].to_json
