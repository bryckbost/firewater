# encoding: utf-8
require 'bundler/setup'
Bundler.require
require 'sinatra/mongo'
MultiJson.engine = :yajl

set :mongo, ENV['MONGOHQ_URL']

get '/' do
  @liquors = mongo["liquors"].find().to_a
  erb :index
end

get '/api/all' do
  content_type :json
  MultiJson.encode mongo["liquors"].find().to_a
end

get '/api/search' do
  content_type :json
  MultiJson.encode mongo["liquors"].find({"BRAND NAME" => /#{params[:q]}/}).to_a
end

