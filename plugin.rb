# name: ghostban
# about: Hide a user's posts
# version: 0.0.2
# authors: cap_dvij
enabled_site_setting :ghostban_enabled


# Add a custom post field to store the hidden status
Post.register_custom_field_type('hidden_by', :integer)

after_initialize do
  module ::DiscourseGhostbanPostToggle
    def self.show_toggle_button(post, user)
      # Check if the user is staff or admin
      return false unless user&.staff?

      # Check if the post is hidden
      post.custom_fields['hidden_by'].nil?
    end
  end

  Post.register_custom_field_type('hidden_by', :integer)

  # Override the method to show/hide posts
  Post.class_eval do
    def show_toggle_button(user)
      ::DiscourseGhostbanPostToggle.show_toggle_button(self, user)
    end

    def hide_post(user)
      # Check if the user is staff or admin
      return unless user&.staff?

      # Hide the post and set the 'hidden_by' field
      self.custom_fields['hidden_by'] = user.id
      self.save!
    end

    def unhide_post(user)
      # Check if the user is staff or admin
      return unless user&.staff?

      # Unhide the post by removing the 'hidden_by' field
      self.custom_fields['hidden_by'] = nil
      self.save!
    end
  end
end

# Override post visibility logic
module ::DiscourseGhostbanPostVisibility
  def custom_fields_to_check(post, user)
    fields = super

    # If the post is hidden, only allow admin/staff and the user to see it
    if post.custom_fields['hidden_by'].present? && post.custom_fields['hidden_by'] != user.id
      fields << 'hidden_by'
    end

    fields
  end
end

PostGuardian.class_eval do
  prepend ::DiscourseGhostbanPostVisibility
end

# Make replies to hidden posts visible to admin and the user
module ::DiscourseGhostbanRepliesVisibility
  def custom_fields_to_check(topic, user)
    fields = super

    # Check if the topic contains a hidden post
    hidden_post_ids = topic.posts.select { |post| post.custom_fields['hidden_by'].present? }.map(&:id)

    # If the user is the author of a hidden post, they can see replies
    if hidden_post_ids.present? && user&.id.present?
      fields << 'hidden_by' if hidden_post_ids.include?(user.id)
    end

    fields
  end
end

TopicGuardian.class_eval do
  prepend ::DiscourseGhostbanRepliesVisibility
end

