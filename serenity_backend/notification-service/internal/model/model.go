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

type Notification struct {
	Base
	UserID  string `gorm:"size:36;index" json:"userId"`
	Type    string `gorm:"size:50" json:"type"` // follow | like | chat | system
	Title   string `gorm:"size:255" json:"title"`
	Body    string `gorm:"type:text" json:"body"`
	ActorID string `gorm:"size:36" json:"actorId"`
	Data    string `gorm:"type:text" json:"data"`
	IsRead  bool   `gorm:"default:false" json:"isRead"`
}
