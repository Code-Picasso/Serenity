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

type Post struct {
	Base
	UserID    string  `gorm:"size:36;index" json:"userId"`
	Text      string  `gorm:"type:text" json:"text"`
	ImageURL  string  `gorm:"type:text" json:"imageUrl"`
	ReshareID *string `gorm:"size:36;index" json:"reshareId"`
	LikeCount int     `gorm:"default:0" json:"likeCount"`
}

type SavedItem struct {
	Base
	UserID    string `gorm:"size:36;index:idx_saved_user,unique" json:"userId"`
	PostID    string `gorm:"size:36;index:idx_saved_user,unique" json:"postId"`
	ArticleID string `gorm:"size:36;index:idx_saved_user,unique" json:"articleId"`
}

type Like struct {
	Base
	UserID string `gorm:"size:36;index:idx_like_user_post,unique" json:"userId"`
	PostID string `gorm:"size:36;index:idx_like_user_post,unique" json:"postId"`
}
