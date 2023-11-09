# Create a migration to add the is_reply_to_ghostbanned column to the posts table
class AddIsReplyToGhostbannedToPosts < ActiveRecord::Migration[6.0]
    def change
      add_column :posts, :is_reply_to_ghostbanned, :boolean, default: false
    end
  end
  