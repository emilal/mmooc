require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'json'

Dotenv.load

# http://tools.ietf.org/html/rfc6749#section-1.2
# https://canvas.instructure.com/doc/api/file.oauth.html

enable :session

conn = Faraday.new(url: "http://#{ENV['API_HOST']}:#{ENV['API_PORT']}/")

get '/' do
  response_type = "code"
  redirect_uri = url("/grant")
  state = "XXXXX" # FIXME unique ID saved in state, check
                  # session[state] == request[state]

  # request authorization grant
  url = "http://#{ENV['API_HOST']}:#{ENV['API_PORT']}/login/oauth2/auth"
  url << "?client_id=#{ENV['API_CLIENT_ID']}"
  url << "&response_type=#{response_type}"
  url << "&redirect_uri=#{redirect_uri}"
  url << "&state=#{state}"
  redirect url
end

get '/grant' do
  code = request["code"]
  state = request["state"]
  redirect_uri = url("/token")

  res = conn.post "/login/oauth2/token", {
                    client_id: ENV['API_CLIENT_ID'],
                    client_secret: ENV['API_CLIENT_KEY'],
                    redirect_uri: redirect_uri,
                    code: code,
                  }

  res = JSON.parse res.body
  session['access_token'] = res['access_token']

  redirect '/courses'
end

get '/courses' do
  res = conn.get "/api/v1/accounts/1/courses" do |req|
    req.headers['Authorization'] = "Bearer #{session['access_token']}"
  end
  @courses = JSON.parse res.body
  haml :courses
end

get '/test' do
  haml :test
end
