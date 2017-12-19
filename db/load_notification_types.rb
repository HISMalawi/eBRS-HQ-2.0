puts "Loading Notification Types"

CSV.foreach("#{Rails.root}/app/assets/data/notification_types.csv", :headers => true) do |row|

 NotificationType.create!(
    name: row[1].squish,
    description: (row[2].squish rescue ""),
	  level: row[0],
    trigger_status_id: Status.where(:name => row[4]).first.id,
    role_id: Role.where(role: row[3],level: row[0]).first.id)

end
puts "Loaded Notification Types !!!"
