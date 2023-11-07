# name: ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.6
# authors: cap_dvij

enabled_site_setting :ghostban_enabled

after_initialize do
  module ::DiscourseGhostbanTopicView
    def filter_post_types(posts)
      result = super(posts)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        ghostbanned_user_ids = User.where(username_lower: SiteSetting.ghostban_users.split('|')).pluck(:id)
        ghostbanned_user_ids << @user&.id if @user&.admin?
        result.where('posts.user_id IN (?) OR topics.archetype = ?', ghostbanned_user_ids, 'private_message')
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
        ghostbanned_user_ids = User.where(username_lower: SiteSetting.ghostban_users.split('|')).pluck(:id)
        ghostbanned_user_ids << @user&.id if @user&.admin?
        result.where('topics.user_id IN (?) OR topics.archetype = ?', ghostbanned_user_ids, 'private_message')
      end
    end
  end

  class ::TopicQuery
    prepend ::DiscourseGhostbanTopicQuery
  end

  module ::DiscourseGhostbanPostAlerter
    def create_notification(user, type, post, opts = {})
      if (SiteSetting.ghostban_show_to_staff && user&.staff?) || SiteSetting.ghostban_users.split('|').include?(post.user&.username_lower)
        super(user, type, post, opts)
      end
    end
  end

  class ::PostAlerter
    prepend ::DiscourseGhostbanPostAlerter
  end

  module ::DiscourseGhostbanPostCreator
    def update_topic_stats
      if SiteSetting.ghostban_users.split('|').include?(@post.user&.username_lower)
        super
      end
    end

    def update_user_counts
      if SiteSetting.ghostban_users.split('|').include?(@post.user&.username_lower)
        super
      end
    end
  end

  class ::PostCreator
    prepend ::DiscourseGhostbanPostCreator
  end
end
