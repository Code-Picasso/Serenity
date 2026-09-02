package repository

import (
	"errors"

	"gorm.io/gorm"

	"serenity-user-service/internal/model"
)

type Repository struct {
	db *gorm.DB
}

func New(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) GetProfile(userID string) (*model.Profile, error) {
	var p model.Profile
	if err := r.db.Where("user_id = ?", userID).First(&p).Error; err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *Repository) EnsureProfile(userID, username, name string) (*model.Profile, error) {
	p, err := r.GetProfile(userID)
	if err == nil {
		return p, nil
	}
	if err != gorm.ErrRecordNotFound {
		return nil, err
	}
	profile := model.Profile{UserID: userID, Username: username, Name: name, IsPublic: true}
	if err := r.db.Create(&profile).Error; err != nil {
		return nil, err
	}
	return &profile, nil
}

func (r *Repository) UpdateProfile(userID string, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}
	return r.db.Model(&model.Profile{}).Where("user_id = ?", userID).Updates(updates).Error
}

func (r *Repository) TopReaders(limit int) ([]model.Profile, error) {
	var profiles []model.Profile
	err := r.db.Where("is_public = ?", true).
		Order("activity_score DESC").
		Limit(limit).
		Find(&profiles).Error
	return profiles, err
}

func (r *Repository) IncrementActivity(userID, activityType string) error {
	updates := map[string]interface{}{"activity_score": gorm.Expr("activity_score + 1")}
	switch activityType {
	case "read":
		updates["reads_count"] = gorm.Expr("reads_count + 1")
	case "share":
		updates["shares_count"] = gorm.Expr("shares_count + 1")
	case "post":
		updates["posts_count"] = gorm.Expr("posts_count + 1")
	case "chat":
		updates["chats_count"] = gorm.Expr("chats_count + 1")
	}
	return r.db.Model(&model.Profile{}).Where("user_id = ?", userID).Updates(updates).Error
}

func (r *Repository) Follow(followerID, followeeID string) error {
	if followerID == followeeID {
		return errors.New("cannot follow yourself")
	}
	return r.db.Transaction(func(tx *gorm.DB) error {
		var existing model.Follow
		err := tx.Where("follower_id = ? AND followee_id = ?", followerID, followeeID).First(&existing).Error
		if err == nil {
			return nil // already following
		}
		if err != gorm.ErrRecordNotFound {
			return err
		}
		if c := tx.Create(&model.Follow{FollowerID: followerID, FolloweeID: followeeID}).Error; c != nil {
			return c
		}
		if err := tx.Model(&model.Profile{}).Where("user_id = ?", followeeID).
			UpdateColumn("followers_count", gorm.Expr("followers_count + 1")).Error; err != nil {
			return err
		}
		return tx.Model(&model.Profile{}).Where("user_id = ?", followerID).
			UpdateColumn("following_count", gorm.Expr("following_count + 1")).Error
	})
}

func (r *Repository) Unfollow(followerID, followeeID string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		res := tx.Where("follower_id = ? AND followee_id = ?", followerID, followeeID).Delete(&model.Follow{})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return nil
		}
		if err := tx.Model(&model.Profile{}).Where("user_id = ?", followeeID).
			UpdateColumn("followers_count", gorm.Expr("GREATEST(followers_count - 1, 0)")).Error; err != nil {
			return err
		}
		return tx.Model(&model.Profile{}).Where("user_id = ?", followerID).
			UpdateColumn("following_count", gorm.Expr("GREATEST(following_count - 1, 0)")).Error
	})
}

func (r *Repository) IsFollowing(followerID, followeeID string) bool {
	var count int64
	r.db.Model(&model.Follow{}).
		Where("follower_id = ? AND followee_id = ?", followerID, followeeID).
		Count(&count)
	return count > 0
}

func (r *Repository) ListFollowers(userID string) ([]model.Profile, error) {
	var follows []model.Follow
	if err := r.db.Where("followee_id = ?", userID).Find(&follows).Error; err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(follows))
	for _, f := range follows {
		ids = append(ids, f.FollowerID)
	}
	if len(ids) == 0 {
		return []model.Profile{}, nil
	}
	var profiles []model.Profile
	err := r.db.Where("user_id IN ?", ids).Find(&profiles).Error
	return profiles, err
}

func (r *Repository) ListFollowing(userID string) ([]model.Profile, error) {
	var follows []model.Follow
	if err := r.db.Where("follower_id = ?", userID).Find(&follows).Error; err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(follows))
	for _, f := range follows {
		ids = append(ids, f.FolloweeID)
	}
	if len(ids) == 0 {
		return []model.Profile{}, nil
	}
	var profiles []model.Profile
	err := r.db.Where("user_id IN ?", ids).Find(&profiles).Error
	return profiles, err
}
