package repository

import (
	"gorm.io/gorm"

	"serenity-post-service/internal/model"
)

type Repository struct {
	db *gorm.DB
}

func New(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) ListPosts(page, limit int) ([]model.Post, int64, error) {
	var total int64
	if err := r.db.Model(&model.Post{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var items []model.Post
	err := r.db.Order("created_at DESC").Offset((page - 1) * limit).Limit(limit).Find(&items).Error
	return items, total, err
}

func (r *Repository) ListPostsByUser(userID string, page, limit int) ([]model.Post, error) {
	var items []model.Post
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").
		Offset((page - 1) * limit).Limit(limit).Find(&items).Error
	return items, err
}

func (r *Repository) ListReshared(userID string) ([]model.Post, error) {
	var items []model.Post
	err := r.db.Where("user_id = ? AND reshare_id IS NOT NULL", userID).
		Order("created_at DESC").Find(&items).Error
	return items, err
}

func (r *Repository) GetPost(id string) (*model.Post, error) {
	var post model.Post
	if err := r.db.First(&post, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *Repository) CreatePost(post *model.Post) error {
	return r.db.Create(post).Error
}

func (r *Repository) DeletePost(id, userID string) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&model.Post{}).Error
}

func (r *Repository) SavePost(userID, postID string) error {
	var existing model.SavedItem
	err := r.db.Where("user_id = ? AND post_id = ?", userID, postID).First(&existing).Error
	if err == nil {
		return nil // already saved
	}
	if err != gorm.ErrRecordNotFound {
		return err
	}
	return r.db.Create(&model.SavedItem{UserID: userID, PostID: postID}).Error
}

func (r *Repository) UnsavePost(userID, postID string) error {
	return r.db.Where("user_id = ? AND post_id = ?", userID, postID).Delete(&model.SavedItem{}).Error
}

func (r *Repository) ListSavedPosts(userID string) ([]model.Post, error) {
	var items []model.SavedItem
	if err := r.db.Where("user_id = ? AND post_id <> ''", userID).Find(&items).Error; err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(items))
	for _, it := range items {
		ids = append(ids, it.PostID)
	}
	if len(ids) == 0 {
		return []model.Post{}, nil
	}
	var posts []model.Post
	err := r.db.Where("id IN ?", ids).Order("created_at DESC").Find(&posts).Error
	return posts, err
}

func (r *Repository) ToggleLike(userID, postID string) (bool, error) {
	var liked bool
	err := r.db.Transaction(func(tx *gorm.DB) error {
		var existing model.Like
		err := tx.Where("user_id = ? AND post_id = ?", userID, postID).First(&existing).Error
		if err == nil {
			if del := tx.Delete(&existing).Error; del != nil {
				return del
			}
			liked = false
			return tx.Model(&model.Post{}).Where("id = ?", postID).
				UpdateColumn("like_count", gorm.Expr("GREATEST(like_count - 1, 0)")).Error
		}
		if err != gorm.ErrRecordNotFound {
			return err
		}
		if c := tx.Create(&model.Like{UserID: userID, PostID: postID}).Error; c != nil {
			return c
		}
		liked = true
		return tx.Model(&model.Post{}).Where("id = ?", postID).
			UpdateColumn("like_count", gorm.Expr("like_count + 1")).Error
	})
	return liked, err
}
