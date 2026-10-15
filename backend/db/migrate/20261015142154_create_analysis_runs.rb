class CreateAnalysisRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :analysis_runs do |t|
      t.string :status, null: false, default: "pending"
      t.jsonb :results, null: false, default: {}
      t.text :error_message

      t.timestamps
    end
  end
end
