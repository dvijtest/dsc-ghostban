
class AddIsReplyToGhostbannedToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :is_reply_to_ghostbanned, :boolean, default: false
  end
end
