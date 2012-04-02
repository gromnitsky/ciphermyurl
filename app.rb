require 'pathname'
require 'ostruct'
require 'sinatra'
require 'rack/recaptcha'
require 'net/http'
require 'stringio'

require_relative 'vendor/flash'

require_relative 'lib/ciphermyurl/meta'
require_relative 'lib/ciphermyurl/db'
require_relative 'lib/ciphermyurl/api'
require_relative 'lib/ciphermyurl/auth'
include CipherMyUrl

require_relative 'config/sinatra'

enable :sessions
use Rack::Flash, sweep: true

use Rack::Recaptcha, public_key: settings.recaptcha_public_key, private_key: settings.recaptcha_private_key
helpers Rack::Recaptcha::Helpers

configure do
  set :sessions, expire_after: 4 # seconds
  HDR_ERROR = "X-#{Meta::NAME}-Error"
end

helpers do
  def myhalt(code, msg)
    headers HDR_ERROR => msg.to_s if msg
  
    session[:halt] = msg.to_s
    halt code
  end
end

error 400..510 do
  "<h1>#{response.status}</h1>\n" +
    (session[:halt] ? "Error: #{session[:halt]}\n" : "")
end


# Return a generated slot number as 201 with text/plain or http error:
#
# [400]  bad request
# [401]  unauthorized
# [500]  couldn't pack
#
# Request body must contain JSON:
#
# { data: '...', pw: '...', keyshash: '...' }
#
# FIXME: check request.content_length
post "/api/#{Api::VERSION}/pack" do
#  pp request
  request.body.rewind
  slot = nil
  begin
    slot = Api.pack Api.packRequestRead(request.body)
    fail RuntimeError, 'failed to create a new slot' unless slot
  rescue ApiUnauthorizedError
    myhalt 401, $!
  rescue ApiBadRequestError
    myhalt 400, $!
  rescue
    myhalt 500, $!
  end

  content_type 'text/plain'
  slot
end

# Requred params:
#
# [slot]  a number > 0
# [pw]    a password for unpacking the slot
#
# Return a data from the slot as text/plain or http error:
#
# [400]  bad request
# [403]  password is invalid
# [404]  slot not found
# [500]  couldn't unpack
get "/api/0.0.1/unpack" do
  r = nil
  begin
    r = Api.unpack Api.unpackRequestRead(params)
    fail RuntimeError, 'unpack failed' unless r
  rescue ApiBadRequestError
    myhalt 400, $!
  rescue ApiUnauthorizedError
    myhalt 403, $!
  rescue ApiInvalidSlotError
    myhalt 404, $!
  rescue
    myhalt 500, $!
  end

  content_type 'text/plain'
  r
end


### User in the browser

helpers do
  def local_get(url, query_string = nil)
    h = {}
    h['PATH_INFO'] = url
    h['QUERY_STRING'] = query_string if query_string
    call env.merge(h)
  end
  
  def local_post(url, data)
#    pp request.env
    request.env['rack.input'], request.env['data.input'] = StringIO.new(data), request.env['rack.input']
    call env.merge('PATH_INFO' => url)
  end

  def redirect_with_session(path, params)
    if params
      params.each {|k,v| session[k] = v }
    end

    redirect path
  end
end

# Optional params:
#
# [pw]  a password for unpacking the slot
get %r{/([0-9]+)} do |slot|
  data = nil
  if params['pw']
    # run rack call to unpack the slot
    status, headers, body = local_get "/api/#{Api::VERSION}/unpack", "slot=#{slot}&pw=#{params['pw']}"
    data = body.first if status == 200
  end
  
  haml :unpack, :locals => { slot: slot, data: data }
end

get '/' do
  haml :pack, :locals => {
    data_max: CipherMyUrl::Data::DATA_MAX,
    pw_min: CipherMyUrl::Data::PW_MIN,
    recaptcha_public_key: settings.recaptcha_public_key,
    
    my_session: session,
  }
end

# Request body must contain:
#
# data
# pw
# recaptcha_challenge_field
# recaptcha_response_field
post '/b/pack' do
  unless recaptcha_valid?
    flash[:error] = 'captcha validation failed'
    redirect_with_session('/', params)
  end

  status, headers, body = local_post("/api/#{Api::VERSION}/pack", {
                                       data: params['data'],
                                       pw: params['pw'],
                                       keyshash: Api::BROWSER_USER_KEYSHASH
                                     }.to_json)
  unless status == 200
    flash[:error] = headers[HDR_ERROR]
    redirect_with_session('/', params)
  end

  session.clear
  haml :b_pack, :locals => {
    slot: body.first,
    pw: params[:pw]
  }
end
