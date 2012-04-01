require 'pathname'
require 'ostruct'
require 'sinatra'

require_relative 'lib/ciphermyurl/db'
require_relative 'lib/ciphermyurl/api'
require_relative 'lib/ciphermyurl/auth'
include CipherMyUrl

require_relative 'config/sinatra'

configure do
  set :myError, OpenStruct.new
end

error 400..510 do
  "<h1>#{response.status}</h1>\n" +
    (settings.myError.last ? "Error: #{settings.myError.last}\n" : "")
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
  request.body.rewind
  slot = nil
  begin
    slot = Api.pack Api.packRequestRead(request.body)
    fail RuntimeError, 'failed to create a new slot' unless slot
  rescue ApiUnauthorizedError
    settings.myError.last = $!
    halt 401
  rescue ApiBadRequestError
    settings.myError.last = $!
    halt 400
  rescue
    settings.myError.last = $!
    halt 500
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
    settings.myError.last = $!
    halt 400
  rescue ApiUnauthorizedError
    settings.myError.last = $!
    halt 403
  rescue ApiInvalidSlotError
    settings.myError.last = $!
    halt 404
  rescue
    settings.myError.last = $!
    halt 500
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
end

# Optional params:
#
# [pw]  a password for unpacking the slot
get %r{/([0-9]+)} do |slot|
  data = nil
  if params['pw']
    # run api call to unpack the slot
    status, headers, body = local_get "/api/#{Api::VERSION}/unpack", "slot=#{slot}&pw=#{params['pw']}"
    data = body.first if status == 200
  end
  
  haml :unpack, :locals => { slot: slot, data: data }
end

get '/' do
  haml :pack
end

