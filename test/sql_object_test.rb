# $LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
require 'active_record_lite'

# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
ActiveRecordLite::DBConnection.open(cats_db_file_name)

class Cat < ActiveRecordLite::SQLObject
  my_attr_accessible(:name, :owner_id)
end

class Human < ActiveRecordLite::SQLObject
  set_table_name("humans")
  my_attr_accessible(:id, :fname, :lname, :house_id)
end

p Human.find(1)
p Cat.find(1)
p Cat.find(2)

p Human.all
p Cat.all

c = Cat.new(:name => "Gizmo", :owner_id => 1)
c.save
puts "new cat: #{c.inspect}"


puts
puts "Searching for human 1"
h = Human.find(1)
# just run an UPDATE; no values changed, so shouldnt hurt the db
h.save

p h.fname

