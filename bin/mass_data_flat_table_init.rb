require "csv"

ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS mass_data (
      id BIGINT(20) NOT NULL AUTO_INCREMENT,
      Surname VARCHAR(255),
      OtherNames VARCHAR(255),
      FirstName VARCHAR(255),
      DateOfBirthString VARCHAR(255),
      Sex VARCHAR(255),
      Nationality VARCHAR(255),
      Nationality2 VARCHAR(255),
      Status VARCHAR(255),
      TypeOfDelivery VARCHAR(255),
      ModeOfDelivery VARCHAR(255),
      LevelOfEducation VARCHAR(255),
      MotherPin VARCHAR(255),
      MotherSurname VARCHAR(255),
      MotherMaidenName VARCHAR(255),
      MotherFirstName VARCHAR(255),
      MotherOtherNames VARCHAR(255),
      MotherNationality VARCHAR(255),
      FatherPin VARCHAR(255),
      FatherSurname VARCHAR(255),
      FatherFirstName VARCHAR(255),
      FatherOtherNames VARCHAR(255),
      FatherVillageId VARCHAR(255),
      FatherNationality VARCHAR(255),
      EbrsPk VARCHAR(255),
      NrisPk VARCHAR(255),
      PlaceOfBirthDistrictId VARCHAR(255),
      PlaceOfBirthDistrictName VARCHAR(255),
      PlaceOfBirthTAName VARCHAR(255),
      PlaceOfBirthVillageName VARCHAR(255),
      PlaceOfBirthVillageId VARCHAR(255),
      MotherDistrictId VARCHAR(255),
      MotherDistrictName VARCHAR(255),
      MotherTAName VARCHAR(255),
      MotherVillageName VARCHAR(255),
      MotherVillageId VARCHAR(255),
      FatherDistrictId VARCHAR(255),
      FatherDistrictName VARCHAR(255),
      FatherTAName VARCHAR(255),
      FatherVillageName VARCHAR(255),
      EditUser VARCHAR(255),
      EditMachine VARCHAR(255),
      BirthCertificateNumber VARCHAR(255),
      DistrictOfRegistration VARCHAR(255),
      MotherAge VARCHAR(255),
      FatherAge VARCHAR(255),
      DateRegistered VARCHAR(255),
      Category VARCHAR(255),
      PRIMARY KEY (id),
      UNIQUE INDEX id_UNIQUE (id ASC)) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

path = ARGV[0]
entries = Dir.entries(path)

entries.each do |f|
  next if f.length < 5
  i = 0;


  CSV.foreach("#{path}/#{f}", headers: true) do |line|
    next if line[0].strip.match(/^Surname/)

    category = f.split(".")[0]
    puts "#{category}: #{i}" if (i % 100 == 0)

    line = line.collect{|l| l.to_a[1].to_s.gsub('"', "'")}
    values  = line.join('", "')

    ActiveRecord::Base.connection.execute <<EOF
    INSERT INTO mass_data VALUES (0, "#{values}", "#{category}");
EOF

    i += 1
  end
end
