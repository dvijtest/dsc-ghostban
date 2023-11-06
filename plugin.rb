# name: ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.2
# authors: cap_dvij
enabled_site_setting :ghostban_enabled


after_initialize do

  module ::DiscourseGhostbanTopicView
    def filter_post_types(posts)
      result = super(posts)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'posts.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?)',
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
=begin
    def create_notification(user, type, post, opts = {})
      if (SiteSetting.ghostban_show_to_staff && user&.staff?) || SiteSetting.ghostban_users.split('|').find_index(post.user&.username_lower).nil?
        super(user, type, post, opts)
      end
    end
  end
=end

    def create_notification(user, type, post, opts = {})
      if user&.staff?
        super(user, type, post, opts)
      else
        # Check if the post is by a shadowbanned user
        shadowbanned_users = SiteSetting.ghostban_users.split('|')
        if shadowbanned_users.include?(post.user&.username_lower)
        # Allow admins to reply to hidden posts by shadowbanned users
          super(user, type, post, opts)
        else
          # Hide the notification for non-shadowbanned users
          opts[:notification_type] = Notification.types[:silenced]
          super(user, type, post, opts)
        end
      end
    end
  end


  class ::PostAlerter
    prepend ::DiscourseGhostbanPostAlerter
  end

  module ::DiscourseGhostbanPostCreator
    def update_topic_stats
      if SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil?
        super
      end
    end
    def update_user_counts
      if SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil?
        super
      end
    end
  end

  class ::PostCreator
    prepend ::DiscourseGhostbanPostCreator
  end
end
