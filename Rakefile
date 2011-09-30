require "bundler/setup"
Bundler.require
require 'csv'
require 'json'
require 'uri'

namespace :import do
  def mongo
    url = URI(ENV['MONGOHQ_URL'])
    connection = Mongo::Connection.new(url.host, url.port)
    mongo = connection.db(url.path[1..-1], {})
    if url.user && url.password
      mongo.authenticate(url.user, url.password)
    end
    mongo
  end

  desc "import price book"
  task :price_book do
    CSV.foreach("docs/price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
      import_row(row)
    end
  end

  desc "import supplemental price book"
  task :supplemental do
    CSV.foreach("docs/supplemental_price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
      import_row(row)
    end
  end

  def import_row(row)
    if row["BRAND NAME"] && row["MINIMUM"]
      row_hash = row.to_hash.delete_if{|k,v| k.nil?}
      mongo.collection("liquors").insert row_hash
    end
  end

  desc "convert types"
  task :convert_types do
    liquors_collection = mongo.collection("liquors")
    liquors_collection.find().each do |liquor|
      liquor["ADA"] = liquor["ADA"].to_i
      liquor["LIQ"] = liquor["LIQ"].to_i
      liquor["PROOF"] = liquor["PROOF"].to_f
      liquor["SIZE"] = liquor["SIZE"].to_i
      liquor["PACK"] = liquor["PACK"].to_i
      liquor["BASE"] = liquor["BASE"].to_f
      liquor["ON PREM"] = liquor["ON PREM"].to_f
      liquor["OFF PREM"] = liquor["OFF PREM"].to_f
      liquor["MINIMUM"] = liquor["MINIMUM"].to_f
      liquors_collection.update({"_id" => liquor["_id"]}, liquor)
    end
  end

  desc "add value key"
  task :add_value do
    mongo.collection("liquors").find().each do |liquor|
      value = ((liquor["PROOF"] * liquor["SIZE"]) / liquor["MINIMUM"]).to_f
      mongo.collection("liquors").update({"_id" => liquor["_id"]}, {"$set" => {"VALUE" => value}})
    end
  end
end
