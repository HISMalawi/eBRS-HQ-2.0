status_ids = Status.where(["name IN (?)", ["HQ-POTENTIAL DUPLICATE-TBA","HQ-NOT DUPLICATE-TBA",
                                           "HQ-POTENTIAL DUPLICATE","HQ-DUPLICATE"]]).pluck :status_id
all = PotentialDuplicate.find_by_sql(
    "
    SELECT pd.* FROM potential_duplicates pd
      INNER JOIN person_record_statuses prs ON prs.voided = 0 AND prs.person_id = pd.person_id
      LEFT JOIN duplicate_records dr ON dr.potential_duplicate_id = pd.potential_duplicate_id
    WHERE dr.potential_duplicate_id IS NULL AND resolved = '0' AND status_id IN (#{status_ids.join(',')})
  ")

all.each_with_index do |duplicate, i|
  puts "#{i}/#{all.count}"
  hash = PersonService.format_for_elastic_search(duplicate.person_id)
  duplicates = SimpleElasticSearch.query_duplicate_coded(hash, SETTINGS['duplicate_precision'])
  duplicates = duplicates.collect{|dup| dup['_id'].to_s} - [duplicate.person_id.to_s]

  puts "Found: #{duplicates.count}, Linking duplicates"
  duplicates.each do |pid|
      duplicate.create_duplicate(pid)
  end
end


