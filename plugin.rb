# name: ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.3
# authors: cap_dvij

enabled_site_setting :shadowban_enabled

after_initialize do

  module ::DiscourseShadowbanTopicView
    def filter_post_types(posts)
      result = super(posts)
      if SiteSetting.shadowban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'posts.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (posts.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?))',
          SiteSetting.shadowban_users.split('|'),
          @user&.id || 0,
          @user&.id || 0
        )
      end
    end
  end

  class ::TopicView
    prepend ::DiscourseShadowbanTopicView
  end

  module ::DiscourseShadowbanTopicQuery
    def default_results(options = {})
      result = super(options)
      if SiteSetting.shadowban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'topics.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (topics.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?))',
          SiteSetting.shadowban_users.split('|'),
          @user&.id || 0,
          @user&.id || 0
        )
      end
    end
  end

  class ::TopicQuery
    prepend ::DiscourseShadowbanTopicQuery
  end

  module ::DiscourseShadowbanPostAlerter
    def create_notification(user, type, post, opts = {})
      if (SiteSetting.shadowban_show_to_staff && user&.staff?) || SiteSetting.shadowban_users.split('|').find_index(post.user&.username_lower).nil?
        super(user, type, post, opts)
      end
    end
  end

  class ::PostAlerter
    prepend ::DiscourseShadowbanPostAlerter
  end

  module ::DiscourseShadowbanPostCreator
    def update_topic_stats
      if SiteSetting.shadowban_users.split('|').find_index(@post.user&.username_lower).nil?
        super
      end
    end
    def update_user_counts
      if SiteSetting.shadowban_users.split('|').find_index(@post.user&.username_lower).nil?
        super
      end
    end
  end

  class ::PostCreator
    prepend ::DiscourseShadowbanPostCreator
  end
end
