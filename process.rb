require "bundler/setup"
Bundler.require

# db = Mongo::Connection.new.db("firewater_development")
# collection = db.collection("michigan")
# collection.insert(doc)

pdf = Grim.reap("Price_Book_1-30-11_thru_4-30-11_342054_7.pdf")
pdf.each do |page|
  puts page.text
end