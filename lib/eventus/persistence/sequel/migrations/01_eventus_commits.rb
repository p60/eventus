Sequel.migration do
  up do
    create_table :eventus_events do
      primary_key :id
      column :name, String, null: false
      column :time, DateTime, null: false
      column :sid, String, null: false
      column :sequence, Integer, null: false
      column :dispatched, TrueClass, null: false, default: false
      column :body, :json, null: false

      unique [:sid, :sequence]
      index :sid
      index :time
    end
  end

  down do
    drop_table :eventus_events
  end
end

