# encoding: utf-8

require 'rubygems'
require 'bundler'
Bundler.require

enable :sessions

WeiboOAuth2::Config.api_key = '1951852920'
WeiboOAuth2::Config.api_secret = '8f74d5247457c7e868f605b965a03d25'
WeiboOAuth2::Config.redirect_uri = 'http://127.0.0.1:4567/callback'

get '/' do
  client = WeiboOAuth2::Client.new
  if session[:access_token] && !client.authorized?
    token = client.get_token_from_hash({:access_token => session[:access_token], :expires_at => session[:expires_at]}) 
    p "*" * 80 + "validated"
    p token.inspect
    p token.validated?
    
    unless token.validated?
      reset_session
      redirect '/connect'
      return
    end
  end
  if session[:uid]
    @user = client.users.show_by_uid(session[:uid]) 
    @statuses = client.statuses
  end
  haml :index
end

get '/getusertimeline' do 
  p "*" * 80 + "getusertimeline"
  client = WeiboOAuth2::Client.new
  aces_token = session[:access_token]
  statuses = client.statuses
  @dataa =  statuses.user_timeline({:access_token => aces_token, :uid => 2556033090})
  p dataa
end

get '/connect' do
  client = WeiboOAuth2::Client.new
  redirect client.authorize_url
end

get '/callback' do
  client = WeiboOAuth2::Client.new
  access_token = client.auth_code.get_token(params[:code].to_s)
  session[:uid] = access_token.params["uid"]
  session[:access_token] = access_token.token
  session[:expires_at] = access_token.expires_at
  p "*" * 80 + "callback"
  p access_token.inspect
  @user = client.users.show_by_uid(session[:uid].to_i)

  redirect '/getusertimeline'
end

get '/logout' do
  reset_session
  redirect '/'
end 

get '/screen.css' do
  content_type 'text/css'
  sass :screen
end

post '/update' do
  client = WeiboOAuth2::Client.new
  client.get_token_from_hash({:access_token => session[:access_token], :expires_at => session[:expires_at]}) 
  statuses = client.statuses

  unless params[:file] && (pic = params[:file].delete(:tempfile))
    statuses.update(params[:status])
  else
    status = params[:status] || '图片'
    statuses.upload(status, pic, params[:file])
  end

  redirect '/'
end

helpers do 
  def reset_session
    session[:uid] = nil
    session[:access_token] = nil
    session[:expires_at] = nil
  end
end