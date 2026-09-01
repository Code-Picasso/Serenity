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

// Article is a normalized content item aggregated from the external providers.
type Article struct {
	Base
	Source      string    `gorm:"size:50;uniqueIndex:idx_article_source" json:"source"`
	SourceID    string    `gorm:"size:255;uniqueIndex:idx_article_source" json:"sourceId"`
	Title       string    `gorm:"type:text" json:"title"`
	Description string    `gorm:"type:text" json:"description"`
	Content     string    `gorm:"type:text" json:"content"`
	URL         string    `gorm:"type:text" json:"url"`
	ImageURL    string    `gorm:"type:text" json:"imageUrl"`
	Author      string    `gorm:"size:255" json:"author"`
	Category    string    `gorm:"size:50;index" json:"category"`
	Topic       string    `gorm:"size:50;index" json:"topic"`
	PublishedAt time.Time `gorm:"index" json:"publishedAt"`
}

// UserInterest is a single selected topic for a user.
type UserInterest struct {
	Base
	UserID string `gorm:"size:36;index:idx_interest_user_topic,unique" json:"userId"`
	Topic  string `gorm:"size:50;index:idx_interest_user_topic,unique" json:"topic"`
}

// SavedArticle bookmarks an article for a user.
type SavedArticle struct {
	Base
	UserID    string `gorm:"size:36;index:idx_saved_article,unique" json:"userId"`
	ArticleID string `gorm:"size:36;index:idx_saved_article,unique" json:"articleId"`
}
