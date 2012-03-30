require 'pp'
require 'pathname'
require 'ostruct'

require_relative 'lib/ciphermyurl/db'
require_relative 'lib/ciphermyurl/api'
require_relative 'lib/ciphermyurl/auth'
include CipherMyUrl

require_relative 'config/sinatra'
require_relative 'config/init'

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
get "/api/#{Api::VERSION}/unpack" do
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

get /([0-9]+)/ do |key|
  haml :unpack, :locals => { key: key }
end

get '/' do
  haml :pack
end

