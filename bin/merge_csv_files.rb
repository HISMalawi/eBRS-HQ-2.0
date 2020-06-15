path = ARGV[0]
destination = ARGV[1]

=begin
  This method is used to combine a list of CSV files generated from
  eBRS MYSQL using script bin/data_extract.rb
=end

def merge(list, path, dest)

  list.each do |file_name|

    `head -1 #{path}/#{file_name} > #{dest}` if !File.exist?(dest)
    `sed  1d #{path}/#{file_name} >> temp.csv`
    `sed '/^$/d' temp.csv >> #{dest}`
    `rm temp.csv`
  end
end

files = Dir.entries(path).delete_if{|f| !f.match("csv")}
puts files
puts "#{files.length} Files to be merged"
merge(files, path, destination)
