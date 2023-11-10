# name: dsc-ghostban
# about: Hide a user's posts from everybody else
# version: 0.0.20
# authors: cap_dvij

# define a new site setting called ghostban_posts, which is a list of post numbers or post ids separated by commas
enabled_site_setting :ghostban_posts

after_initialize do
  # ...

  module ::DiscourseGhostbanTopicView
    def filter_post_types(posts)
      result = super(posts)

      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        # change the where clause to check if the post number or post id is in the ghostban_posts site setting
        result.where(
          'posts.post_number NOT IN (?) OR posts.id NOT IN (?)',
          SiteSetting.ghostban_posts.split(','),
          SiteSetting.ghostban_posts.split(',')
        )
      end
    end
  end

  module ::DiscourseGhostbanTopicQuery
    def default_results(options = {})
      result = super(options)
      if SiteSetting.ghostban_show_to_staff && @user&.staff?
        result
      else
        # change the where clause to check if the topic's first post number or post id is in the ghostban_posts site setting
        result.where(
          'topics.posts_count > 1 OR topics.highest_post_number NOT IN (?) OR topics.first_post_id NOT IN (?)',
          SiteSetting.ghostban_posts.split(','),
          SiteSetting.ghostban_posts.split(',')
        )
      end
    end
  end

  module ::DiscourseGhostbanPostAlerter
    def create_notification(user, type, post, opts = {})
      # change the condition to check if the post number or post id is in the ghostban_posts site setting
      if (SiteSetting.ghostban_show_to_staff && user&.staff?) || SiteSetting.ghostban_posts.split(',').find_index(post.post_number.to_s).nil? || SiteSetting.ghostban_posts.split(',').find_index(post.id.to_s).nil?
        super(user, type, post, opts)
      end
    end
  end

  module ::DiscourseGhostbanPostCreator
    def update_topic_stats
      # change the condition to check if the post number or post id is in the ghostban_posts site setting
      unless SiteSetting.ghostban_posts.split(',').find_index(@post.post_number.to_s).nil? || SiteSetting.ghostban_posts.split(',').find_index(@post.id.to_s).nil?
        return
      end

      super
    end

    def update_user_counts
      # change the condition to check if the post number or post id is in the ghostban_posts site setting
      unless SiteSetting.ghostban_posts.split(',').find_index(@post.post_number.to_s).nil? || SiteSetting.ghostban_posts.split(',').find_index(@post.id.to_s).nil?
        return
      end

      super
    end
  end
end
