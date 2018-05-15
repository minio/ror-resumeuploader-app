class CreateUploads < ActiveRecord::Migration[5.0]
  def change
    create_table :uploads do |t|
      t.string :url
      t.string :name

      t.timestamps null: false
    end
  end
end
