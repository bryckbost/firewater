# encoding: utf-8
require 'bundler/setup'
Bundler.require
require 'sinatra/mongo'
require 'active_support/core_ext/string/inflections'
MultiJson.engine = :yajl

if File.exist?('config/application.yml')
  config = YAML.load_file('config/application.yml')
  config.each{|k,v| ENV[k] = v }
end

set :mongo, ENV['MONGOHQ_URL']

helpers do
  def friendly_name(liquor_name)
    liquor_name.downcase.titleize
  end
end

# only set the random liquor for non /api endpoints
before /^\/((?!api).*)/ do
  liquors = mongo["liquors"].find()
  @header_liquor = liquors.skip(rand(liquors.count)).limit(1).first
end

get '/' do
  @liquors = mongo["liquors"].find().limit(150).to_a
  erb :index
end

get '/page/:page' do
  @liquors = mongo["liquors"].find().skip(150 * params[:page].to_i).limit(150).to_a
  erb :index
end

get '/search' do
  @liquors = mongo["liquors"].find({"BRAND NAME" => /#{params[:q]}/i}).to_a
  erb :index
end

get '/api/all' do
  content_type :json
  MultiJson.encode mongo["liquors"].find().to_a
end

get '/api/search' do
  content_type :json
  MultiJson.encode mongo["liquors"].find({"BRAND NAME" => /#{params[:q]}/i}).to_a
end

