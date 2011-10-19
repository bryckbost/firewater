# encoding: utf-8
require 'bundler/setup'
Bundler.require
require 'sinatra/mongo'
require 'sinatra/indextank'
require 'active_support/core_ext/string/inflections'
MultiJson.engine = :yajl

if File.exist?('config/application.yml')
  config = YAML.load_file('config/application.yml')
  config.each{|k,v| ENV[k] = v }
end

set :mongo, ENV['MONGOHQ_URL']
set :indextank, ENV['INDEXTANK_API_URL']

configure :production do
  require 'newrelic_rpm'
end

helpers do
  def friendly_name(liquor)
    if liquor && liquor["BRAND NAME"]
      liquor["BRAND NAME"].downcase.titleize
    else
      ""
    end
  end

  def price_per_milliliter(liquor)
    liquor["PRICE"] / liquor["SIZE"]
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

  def most_expensive
    mongo["liquors"].find({}, :sort => [['MINIMUM', -1]]).limit(1).first
  end

  def cheapest
    mongo["liquors"].find({}, :sort => [['MINIMUM', 1]]).limit(1).first
  end

  def highest_proof
    mongo["liquors"].find({}, :sort => [['PROOF', -1]]).limit(1).first
  end

  def weakest_proof
    mongo["liquors"].find({}, :sort => [['PROOF', 1]]).limit(1).first
  end

  def best_value
    mongo["liquors"].find({}, :sort => [['VALUE', -1]]).limit(1).first
  end

  def biggest_ripoff
    mongo["liquors"].find({}, :sort => [['VALUE', 1]]).limit(1).first
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

get '/liquors/:id' do
  @liquor = mongo["liquors"].find({"_id" => BSON::ObjectId(params[:id])}).first
  erb :show
end

get '/page/:page' do
  @liquors = scope.skip(per_page * params[:page].to_i).limit(per_page).to_a
  @paginate = true
  erb :index
end

get '/search' do
  results = indextank.indexes('idx').search(params[:q], :len => 500)
  liquors = results["results"].map{|r| BSON::ObjectId(r["docid"])}
  @liquors = mongo["liquors"].find({"_id" => {"$in" => liquors}}).to_a
  erb :index
end

# GET /vodka, /scotch, /whisky, /bourbon …
get '/:category' do
  @category = params[:category]
  @liquors = scope({"CATEGORY" => /#{@category}/i}).to_a
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

get '/api/:category' do
  content_type :json
  MultiJson.encode mongo["liquors"].find({"CATEGORY" => /#{params[:category]}/i}).to_a
end
