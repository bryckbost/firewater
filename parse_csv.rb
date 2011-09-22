require "bundler/setup"
Bundler.require
require 'csv'
require 'json'

db = Mongo::Connection.new("localhost").db("firewater_development")
collection = db.collection("liquors")

CSV.foreach("docs/price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
  if row["BRAND NAME"] && row["MINIMUM"]
    row_hash = row.to_hash.delete_if{|k,v| k.nil?}
    collection.insert row_hash
  end
end