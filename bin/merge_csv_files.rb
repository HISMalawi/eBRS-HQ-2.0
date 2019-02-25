path = ARGV[0]

=begin
  This method is used to combine a list of CSV files generated from
  eBRS MYSQL using script bin/data_extract.rb
=end

def merge(list, path)

  list.each do |file_name|

    `head -1 #{path}/#{file_name} > merge-brk.csv` if !File.exist?("merge-brk.csv")
    `sed  1d #{path}/#{file_name} >> temp.csv`
    `sed '/^$/d' temp.csv >> merge-brk.csv`
    `rm temp.csv`
  end
end

files = Dir.entries(path).delete_if{|f| !f.match("csv")}
puts files
puts "#{files.length} Files to be merged"
merge(files, path)