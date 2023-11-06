# name: ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.5
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
          'posts.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (posts.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?)) OR (posts.user_id = ? OR posts.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?))',
          SiteSetting.ghostban_users.split('|'),
          @user&.id || 0,
          @user&.id || 0,
          @user&.id || 0,
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
          'topics.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (topics.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?))',
          SiteSetting.ghostban_users.split('|'),
          @user&.id || 0,
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
      if (SiteSetting.ghostban_show_to_staff && user&.staff?) || SiteSetting.ghostban_users.split('|').find_index(post.user&.username_lower).nil? || user&.admin?
        super(user, type, post, opts)
      end
    end
  end

  class ::PostAlerter
    prepend ::DiscourseGhostbanPostAlerter
  end

  module ::DiscourseGhostbanPostCreator
    def update_topic_stats
      if SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil? || @post.user&.admin?
        super
      end
    end

    def update_user_counts
      if SiteSetting.ghostban_users.split('|').find_index(@post.user&.username_lower).nil? || @post.user&.admin?
        super
      end
    end
  end

  class ::PostCreator
    prepend ::DiscourseGhostbanPostCreator
  end
end
