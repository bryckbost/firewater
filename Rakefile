require "bundler/setup"
Bundler.require
require 'csv'
require 'json'
require 'uri'

if File.exist?('config/application.yml')
  config = YAML.load_file('config/application.yml')
  config.each{|k,v| ENV[k] = v }
end

def mongo
  url = URI(ENV['MONGOHQ_URL'])
  connection = Mongo::Connection.new(url.host, url.port)
  mongo = connection.db(url.path[1..-1], {})
  if url.user && url.password
    mongo.authenticate(url.user, url.password)
  end
  mongo
end

def indextank
  client = IndexTank::Client.new(ENV['INDEXTANK_API_URL'])
  index = client.indexes('idx')
  index
end

namespace :import do
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

  desc "Add categories"
  task :add_categories do
    category ||= nil
    CSV.foreach("docs/supplemental_price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
      # if first row is present && second row is blank
      if !(row[0] !~ /\S/) && row[1] !~ /\S/
        # strip (CONTINUED) from the row
        category = row[0].gsub(/\s\(.+/, "")
      end

      # update this liquor if the row has a brand and a minimum price
      if row["BRAND NAME"] && row["MINIMUM"]
        liquor = mongo.collection("liquors").find({"BRAND NAME" => row["BRAND NAME"], "MINIMUM" => row["MINIMUM"].to_f}).first
        next if !(liquor["CATEGORY"] !~ /\S/)
        mongo.collection("liquors").update({"_id" => liquor["_id"]}, {"$set" => {"CATEGORY" => category}})
      end
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

namespace :indextank do
  desc "add documents to index"
  task :add_documents do
    mongo.collection("liquors").find().each do |liquor|
      indextank.document(liquor["_id"].to_s).add({:text => liquor["BRAND NAME"].downcase,
        :category => (liquor["CATEGORY"] ? liquor["CATEGORY"].downcase : ""),
        :price => liquor["MINIMUM"]
      })
    end
  end
end
