puts Pusher

all = PersonBirthDetail.where(" DATE(created_at) BETWEEN '2019-05-25' AND '#{Date.today.to_s}' ")

total = 0
person_ids = []
all.each do |pbd|
  suspected = false
  total_pid = PersonBirthDetail.where(person_id: pbd.person_id)
  if total_pid.count > 1
    suspected = true
  end

  rels = PersonRelationship.where(person_a: pbd.person_id)
  if rels.length > 4
    suspected = true
  end

  if suspected
    total += 1
    person_ids << pbd.person_id
    puts person_ids.uniq.count
  end
end

person_ids.each do |pid|
  puts pid
  couchdb = Pusher.database.get(pid.to_s)
  puts couchdb.inspect
end
