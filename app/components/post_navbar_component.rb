class PostNavbarComponent < ApplicationComponent
  extend Memoist

  attr_reader :post, :current_user, :search

  def initialize(post:, current_user:, search: nil)
    super
    @post = post
    @current_user = current_user
    @search = search.presence || "status:any"
  end

  def render?
    has_search_navbar? || pools.any? || favgroups.any? || parent_relationships.any?
  end

  def parent_relationships
    include_deleted = post.is_deleted? || (post.parent_id.present? && post.parent.is_deleted?) || CurrentUser.user.show_deleted_children?
    relationship_groups = []
    relationship_groups.push((include_deleted ? post.parent.children : post.parent.children.undeleted).to_a.unshift(post.parent)) if post.parent.present?
    relationship_groups.push((include_deleted ? post.children : post.children.undeleted).to_a.unshift(post)) if post.has_visible_children?
    @parent_relationships ||= relationship_groups
  end

  def pools
    @pools ||= post.pools.undeleted.sort_by do |pool|
      [pool.id == pool_id ? 0 : 1, pool.is_series? ? 0 : 1, pool.name]
    end
  end

  def favgroups
    favgroups = FavoriteGroup.visible(current_user).for_post(post.id)
    favgroups = favgroups.where(creator: current_user).or(favgroups.where(id: favgroup_id))
    favgroups.sort_by do |favgroup|
      [favgroup.id == favgroup_id ? 0 : 1, favgroup.name]
    end
  end

  def has_search_navbar?
    !query.has_metatag?(:order, :ordfav, :ordpool) && pool_id.blank? && favgroup_id.blank? && parent_id.blank?
  end

  def pool_id
    @pool_id ||= query.find_metatag(:pool, :ordpool)&.to_i
  end

  def favgroup_id
    @favgroup_id ||= query.find_metatag(:favgroup, :ordfavgroup)&.to_i
  end

  def parent_id
    @parent_id ||= query.find_metatag(:parent)&.to_i
  end

  def query
    @query ||= PostQueryBuilder.new(search)
  end

  memoize :favgroups
end
