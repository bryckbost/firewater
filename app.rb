require 'bundler/setup'
Bundler.require
require 'sinatra/mongo'
MultiJson.engine = :yajl

set :mongo, ENV['MONGO_URL']

get '/' do
  content_type :json
  MultiJson.encode mongo["liquors"].find().to_a
end

get '/search' do
  content_type :json
  MultiJson.encode mongo["liquors"].find({"BRAND NAME" => /#{params[:q]}/}).to_a
end

