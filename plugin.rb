# name: dsc-ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.12
# authors: cap_dvij

enabled_site_setting :ghostban_enabled

after_initialize do
  # Step 1: Add a boolean column is_reply_to_ghostbanned to the posts table
  add_column :posts, :is_reply_to_ghostbanned, :boolean, default: false, null: false

  # Step 2: Add logic to update is_reply_to_ghostbanned column
  on(:post_created) do |post, _params|
    update_ghostban_status(post)
  end

  on(:post_edited) do |post, _params|
    update_ghostban_status(post)
  end

  def update_ghostban_status(post)
    post.is_reply_to_ghostbanned = should_mark_as_ghostbanned?(post)
    post.save!
  end

  def should_mark_as_ghostbanned?(post)
    return false unless post.reply_to_user_id

    ghostbanned_usernames = SiteSetting.ghostban_users.split('|')
    ghostbanned_usernames.include?(User.find(post.reply_to_user_id)&.username_lower)
  end

  # Step 3: Modify the filter_post_types method
  module ::DiscourseGhostbanTopicView
    def filter_post_types(posts)
      result = super(posts)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'posts.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (posts.is_reply_to_ghostbanned AND NOT posts.user_id IN (SELECT u.id FROM users u WHERE admin))',
          SiteSetting.ghostban_users.split('|'),
          @user&.id || 0
        )
      end
    end
  end

  class ::TopicView
    prepend ::DiscourseGhostbanTopicView
  end

  module ::DiscourseGhostbanTopicQuery
    def default_results(options = {})
      result = super(options)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'topics.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?)',
          SiteSetting.ghostban_users.split('|'),
          @user&.id || 0
        )
      end
    end
  end

  class ::TopicQuery
    prepend ::DiscourseGhostbanTopicQuery
  end

  module ::DiscourseGhostbanPostAlerter
    def create_notification(user, type, post, opts = {})
      if (SiteSetting.ghostban_show_to_staff && user&.staff?) || SiteSetting.ghostban_users.split('|').find_index(post.user&.username_lower).nil?
        super(user, type, post, opts)
      end
    end
  end

  class ::PostAlerter
    prepend ::DiscourseGhostbanPostAlerter
  end

  module ::DiscourseGhostbanPostCreator
    def update_topic_stats
      return unless SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil?

      super
    end

    def update_user_counts
      return unless SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil?

      super
    end
  end

  class ::PostCreator
    prepend ::DiscourseGhostbanPostCreator
  end
end
