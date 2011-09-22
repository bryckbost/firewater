require "bundler/setup"
Bundler.require
require 'csv'
require 'json'
require 'uri'

namespace :import do
  url = URI(ENV['MONGO_URL'])
  connection = Mongo::Connection.new(url.host, url.port)
  mongo = connection.db(url.path[1..-1], {})
  if url.user && url.password
    mongo.authenticate(url.user, url.password)
  end

  desc "import price book"
  task :price_book => :environment do
    CSV.foreach("docs/price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
      import_row
    end
  end

  desc "import supplemental price book"
  task :supplemental => :environment do
    CSV.foreach("docs/supplemental_price_book.csv", {:headers => true, :skip_blanks => true}) do |row|
      import_row
    end
  end

  def import_row
    if row["BRAND NAME"] && row["MINIMUM"]
      row_hash = row.to_hash.delete_if{|k,v| k.nil?}
      mongo.collection("liquors").insert row_hash
    end
  end
end
