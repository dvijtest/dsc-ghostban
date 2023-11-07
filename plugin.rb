# name: ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.9
# authors: cap_dvij

after_initialize do

  module ::DiscourseGhostbanTopicView
    def filter_post_types(posts)
      result = super(posts)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        result.where(
          'posts.user_id NOT IN (SELECT u.id FROM users u WHERE username_lower IN (?) AND u.id != ?) AND NOT (posts.user_id IN (SELECT u.id FROM users u WHERE admin AND u.id != ?))',
          SiteSetting.ghostban_users.split('|'),
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
      # Make the admin's reply to the hidden post visible to the hidden post's author and everyone, by updating the `hidden` attribute of the post to `false`. It will also update the topic stats accordingly.
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        @topic.update!(posts_count: @topic.posts_count + 1, replies_count: @topic.replies_count + 1)
        @topic.posts.where(user_id: @user.id).update_all(hidden: false)
      end

      # Make the admin's topic level post visible to everyone
      if @user&.staff? && @post.topic_level?
        @post.update_attributes(hidden: false)
      end

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
