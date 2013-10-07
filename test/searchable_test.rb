require_relative '../lib/active_record_lite'

# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
DBConnection.open(cats_db_file_name)

class Cat < SQLObject
  set_table_name("cats")
  my_attr_accessible(:id, :name, :owner_id)
end

class Human < SQLObject
  set_table_name("humans")
  my_attr_accessible(:id, :fname, :lname, :house_id)
end

p Cat.where(:name => "Breakfast").first
matt = Human.where(:fname => "Matt").first
p matt

puts
puts "Testing Relation functionality"
puts "getting cats named 'Breakfast'..."
p Cat.where(:name => "Breakfast")
puts
puts "getting cats named 'Breakfast' owned by owner 2 ('Matt')"
p Cat.where(:name => "Breakfast").where(:owner_id => matt.id)
