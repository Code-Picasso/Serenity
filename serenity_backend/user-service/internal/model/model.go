package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Base struct {
	ID        string    `gorm:"primaryKey;size:36" json:"id"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

func (b *Base) BeforeCreate(_ *gorm.DB) error {
	if b.ID == "" {
		b.ID = uuid.NewString()
	}
	return nil
}

type Profile struct {
	Base
	UserID         string `gorm:"size:36;uniqueIndex" json:"userId"`
	Email          string `gorm:"size:255" json:"email"`
	Name           string `gorm:"size:255" json:"name"`
	Username       string `gorm:"size:100;index" json:"username"`
	Bio            string `gorm:"type:text" json:"bio"`
	AvatarURL      string `gorm:"type:text" json:"avatarUrl"`
	IsPublic       bool   `gorm:"default:true" json:"isPublic"`

	ActivityScore  int `gorm:"default:0" json:"activityScore"`
	ReadsCount     int `gorm:"default:0" json:"readsCount"`
	SharesCount    int `gorm:"default:0" json:"sharesCount"`
	PostsCount     int `gorm:"default:0" json:"postsCount"`
	ChatsCount     int `gorm:"default:0" json:"chatsCount"`
	FollowersCount int `gorm:"default:0" json:"followersCount"`
	FollowingCount int `gorm:"default:0" json:"followingCount"`
}

type Follow struct {
	Base
	FollowerID string `gorm:"size:36;index:idx_follow,unique" json:"followerId"`
	FolloweeID string `gorm:"size:36;index:idx_follow,unique" json:"followeeId"`
}
