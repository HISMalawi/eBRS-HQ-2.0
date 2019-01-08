def write_chunks
	
	ids = PersonBirthDetail.pluck :person_id
	chunks = ids.each_slice(25000)

	chunks.each_with_index do |chunk, i|
		File.open("chunks/chunk-#{(i + 1)}", "w"){|f|
			f.write(chunk.join(","))
		}
	end
end

write_chunks
