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

  def per_page
    150
  end

  def current_page
    [params[:page].to_i, 1].max
  end

  def number_of_pages
    liquor_count / per_page
  end

  def liquor_count
    @liquor_count ||= mongo["liquors"].find().count
  end

  def previous_page
    current_page - 1
  end

  def next_page
    current_page + 1
  end

  def scope(options={})
    mongo["liquors"].find(options, :sort => [['BRAND NAME', 1]])
  end
end

# only set the random liquor for non /api endpoints
before /^\/((?!api).*)/ do
  @header_liquor = mongo["liquors"].find().skip(rand(liquor_count)).limit(1).first
end

get '/' do
  @liquors = scope.limit(per_page).to_a
  @paginate = true
  erb :index
end

get '/page/:page' do
  @liquors = scope.skip(per_page * params[:page].to_i).limit(per_page).to_a
  @paginate = true
  erb :index
end

get '/search' do
  @liquors = scope({"BRAND NAME" => /#{params[:q]}/i}).to_a
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

