package repository

import (
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"serenity-feed-service/internal/model"
)

type Repository struct {
	db *gorm.DB
}

func New(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) UpsertArticles(articles []model.Article) error {
	if len(articles) == 0 {
		return nil
	}
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "source"}, {Name: "source_id"}},
		DoNothing: true,
	}).Create(&articles).Error
}

func (r *Repository) CountArticles() (int64, error) {
	var count int64
	err := r.db.Model(&model.Article{}).Count(&count).Error
	return count, err
}

func (r *Repository) ListFeed(interests []string, topic string, page, limit int) ([]model.Article, int64, error) {
	query := r.db.Model(&model.Article{})
	if topic != "" {
		query = query.Where("topic = ?", topic)
	} else if len(interests) > 0 {
		query = query.Where("topic IN ?", interests)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var items []model.Article
	err := query.Order("published_at DESC").Offset((page - 1) * limit).Limit(limit).Find(&items).Error
	return items, total, err
}

func (r *Repository) GetArticle(id string) (*model.Article, error) {
	var article model.Article
	if err := r.db.First(&article, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &article, nil
}

func (r *Repository) Search(q string, page, limit int) ([]model.Article, int64, error) {
	like := "%" + q + "%"
	query := r.db.Model(&model.Article{}).
		Where("title ILIKE ? OR description ILIKE ? OR content ILIKE ?", like, like, like)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var items []model.Article
	err := query.Order("published_at DESC").Offset((page - 1) * limit).Limit(limit).Find(&items).Error
	return items, total, err
}

func (r *Repository) GetInterests(userID string) ([]string, error) {
	var interests []model.UserInterest
	if err := r.db.Where("user_id = ?", userID).Find(&interests).Error; err != nil {
		return nil, err
	}
	topics := make([]string, 0, len(interests))
	for _, i := range interests {
		topics = append(topics, i.Topic)
	}
	return topics, nil
}

func (r *Repository) SaveArticle(userID, articleID string) error {
	var existing model.SavedArticle
	err := r.db.Where("user_id = ? AND article_id = ?", userID, articleID).First(&existing).Error
	if err == nil {
		return nil
	}
	if err != gorm.ErrRecordNotFound {
		return err
	}
	return r.db.Create(&model.SavedArticle{UserID: userID, ArticleID: articleID}).Error
}

func (r *Repository) UnsaveArticle(userID, articleID string) error {
	return r.db.Where("user_id = ? AND article_id = ?", userID, articleID).Delete(&model.SavedArticle{}).Error
}

func (r *Repository) ListSavedArticles(userID string) ([]model.Article, error) {
	var saved []model.SavedArticle
	if err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&saved).Error; err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(saved))
	for _, s := range saved {
		ids = append(ids, s.ArticleID)
	}
	if len(ids) == 0 {
		return []model.Article{}, nil
	}
	var articles []model.Article
	err := r.db.Where("id IN ?", ids).Find(&articles).Error
	return articles, err
}

func (r *Repository) ReplaceInterests(userID string, topics []string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ?", userID).Delete(&model.UserInterest{}).Error; err != nil {
			return err
		}
		for _, t := range topics {
			if err := tx.Create(&model.UserInterest{UserID: userID, Topic: t}).Error; err != nil {
				return err
			}
		}
		return nil
	})
}
