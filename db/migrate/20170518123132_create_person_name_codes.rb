class CreatePersonNameCodes < ActiveRecord::Migration
  def change
    create_table :person_name_codes do |t|

      t.timestamps null: false
    end
  end
end
