require 'pathname'
require 'ostruct'
require 'logger'
require 'sinatra'
require 'rack/recaptcha'
require 'net/http'
require 'stringio'
require 'sinatra/outputbuffer'

require_relative 'vendor/flash'

require_relative 'lib/ciphermyurl/meta'
require_relative 'lib/ciphermyurl/db'
require_relative 'lib/ciphermyurl/api'
require_relative 'lib/ciphermyurl/auth'
require_relative 'lib/ciphermyurl/options'
include CipherMyUrl

$opt = Options.load
require_relative 'config/sinatra'

enable :sessions
use Rack::Flash, sweep: true

use Rack::Recaptcha, public_key: settings.recaptcha_public_key, private_key: settings.recaptcha_private_key
helpers Rack::Recaptcha::Helpers

configure do
  HDR_ERROR = "X-#{Meta::NAME}-Error"
end

helpers do
  def myhalt(code, msg)
    headers HDR_ERROR => msg.to_s if msg
    session[:halt] = msg.to_s

    # FIXME: a kludge for sinatra 1.3.2, remove this for 1.4+
    @responseStatus = code
    
    halt code
  end

  def logBefore
    # mark & log each request
    @requestId = SecureRandom.hex 4
    @responseStatus = nil # FIXME: remove this for 1.4+
    logger.info "#{@requestId} before #{request.ip} #{request.path} #{request.referrer} #{request.user_agent}"
  end

  def logAfter
    # response.status doesn't work in sinatra 1.3.2 for halts
    # FIXME: remove @responseStatus this for 1.4+
    logger.info "#{@requestId} after #{@responseStatus ? @responseStatus : response.status} #{flash[:error]}"
  end
end

error 400..510 do
  "<h1>#{response.status}</h1>\n" +
    (session[:halt] ? "Error: #{session[:halt]}\n" : "")
end

before do
  # Staff for views
  @meta = Meta
  @my_session = session

  logBefore
end

after do
  logAfter
end

# Return a generated slot number as 201 with text/plain or http error:
#
# [400]  bad request
# [401]  unauthorized
# [500]  couldn't pack
#
# Request body must contain JSON:
#
# { data: '...', pw: '...', kpublic: '...', kprivate: '...' }
#
# FIXME: check request.content_length
post "/api/0.0.1/pack" do
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
  status 201
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
get "/api/0.0.1/unpack/:slot" do
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

# Required params:
#
# [slot]
# [pw]
#
# Return empty http 200 with empty body or http error:
#
# [400]  bad request
# [403]  pw is invalid
# [500]  couldn't delete, some nasty error
delete '/api/0.0.1/del/:slot' do
  begin
    Api.del Api.delRequestRead(params)
  rescue ApiBadRequestError
    myhalt 400, $!
  rescue ApiUnauthorizedError
    myhalt 403, $!
  rescue
    myhalt 500, $!
  end

  content_type 'text/plain'
  ""
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

  def menu(current)
    m = {
      "Pack" => url("/") ,
      "Unpack" => url("/1?pw=12345678"),
      "-" => nil,
      "WTF?" => url("/about")
    }

    r = ""
    m.each {|k,v|
      if k == current
        r << "<li class='active'><a href='#'>#{k}</a></li>\n"
      elsif k == '-'
        r << "<li class='divider-vertical'></li>"
      else
        r << "<li><a href='#{v}'>#{k}</a></li>\n"
      end
    }

    "\
<div class='navbar'>
  <div class='navbar-inner'>
    <div class='container-fluid'>
      <span class='brand'>#{Meta::NAME}</span>
         <ul class='nav'>#{r}</ul>
    </div>
  </div>
</div>"
  end

  # Protect from double/triple/etc submitting the same data
  def canPack?(data, pw)
    fail 'packing is unprotected (disabled cookies?)' unless session[:pack_protection]

    current = Digest::SHA256.hexdigest data
    logger.debug "pack_protection=#{session[:pack_protection]}"
    logger.debug "p-current=#{current}, p-last=#{session[:pack_last]}"
    
    unless session[:pack_protection] == 0
      fail 'you have submitted that data already' if session[:pack_last] == current
    end
    
    session[:pack_last] = current
    return true
  end

  def drawCaptcha(t)
    return '[CAPTCHA]' if logger.level == Logger::DEBUG
    recaptcha_tag(:ajax, display: {theme: t})
  end
end

# Optional params:
#
# [pw]  a password for unpacking the slot
get %r{^/([0-9]+)} do |slot|
  data = nil
  if params['pw']
    # run rack call to unpack the slot
    status, headers, body = local_get "/api/#{Meta::API_VERSION}/unpack/#{slot}", "pw=#{params['pw']}"
    data = body.first if status == 200
    flash[:error] = headers[HDR_ERROR] if headers[HDR_ERROR]
  end

  redirect data if CipherMyUrl::Data.valid_uri?(data)
  
  haml :unpack, :locals => {
    slot: slot,
    data: data
  }
end

get '/' do
  haml :pack, :locals => {
    data_max: CipherMyUrl::Data::DATA_MAX,
    pw_min: CipherMyUrl::Data::PW_MIN,
    recaptcha_public_key: settings.recaptcha_public_key,
  }
end

# Request body must contain:
#
# data
# pw
# recaptcha_challenge_field
# recaptcha_response_field
post '/b/pack' do
  session[:pack_protection] ||= 0
  
  unless recaptcha_valid?
    flash[:error] = 'captcha validation failed'
    redirect_with_session('/', params)
  end

  begin
    canPack?(params[:data], params[:pw])
  rescue
    flash[:error] = $!.to_s
    redirect_with_session('/', params)
  end
  
  status, headers, body = local_post("/api/#{Meta::API_VERSION}/pack", {
                                       data: params['data'],
                                       pw: params['pw'],
                                       kpublic: $opt[:webclient][:kpublic],
                                       kprivate: $opt[:webclient][:kprivate]
                                     }.to_json)
  unless status == 201
    session[:pack_protection] = 0
    flash[:error] = headers[HDR_ERROR]
    redirect_with_session('/', params)
  end

  session[:pack_protection] += 1
  
  haml :b_pack, :locals => {
    slot: body.first,
    pw: params[:pw]
  }
end

get '/about' do
  @getCount = MyDB.getCount
  haml :about
end
