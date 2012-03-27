#require 'haml'
#require 'sinatra'
require 'pp'

#require_relative 'config'

configure do
end

configure :production do
  set :haml, ugly: true
end

get /([0-9]+)/ do |key|
  haml :unpack, :locals => { key: key }
end

get '/' do
  haml :pack
end

