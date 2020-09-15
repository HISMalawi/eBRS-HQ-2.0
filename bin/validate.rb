person = Person.where(person_id: 100260157254).first

validate = NIDValidator.validate(person, "T6N502WD")

puts dob_local = (validate["DateOfBirthString"][:local])

puts dob_remote = (validate["DateOfBirthString"][:remote])

puts mothernames_local = (validate["MotherOtherNames"][:local])
puts mothernames_remote = (validate["MotherOtherNames"][:remote])
puts mother_village_local = (validate["MotherVillageName"][:local])
puts mother_village_remote = (validate["MotherVillageName"][:remote])

if dob_local != dob_remote
 puts "date of birth not eqaul"
end

#raise validate.inspect
