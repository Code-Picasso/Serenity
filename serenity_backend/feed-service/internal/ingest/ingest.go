package ingest

import (
	"log"
	"time"

	"gorm.io/gorm"

	"serenity-feed-service/internal/config"
	"serenity-feed-service/internal/model"
	"serenity-feed-service/internal/repository"
)

// Start performs an initial ingestion and then refreshes on a fixed interval.
func Start(db *gorm.DB, cfg config.Config) {
	repo := repository.New(db)
	run := func() {
		if err := SeedAndFetch(repo, cfg); err != nil {
			log.Printf("[ingest] error: %v", err)
		}
	}
	run()

	interval := time.Duration(cfg.IngestIntervalMin) * time.Minute
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for range ticker.C {
			run()
		}
	}()
}

func SeedAndFetch(repo *repository.Repository, cfg config.Config) error {
	count, _ := repo.CountArticles()
	if cfg.MockMode || count == 0 {
		if err := repo.UpsertArticles(MockArticles()); err != nil {
			return err
		}
		if count == 0 {
			log.Println("[ingest] seeded mock articles")
		}
	}

	var all []model.Article
	if cfg.GNewsAPIKey != "" {
		all = append(all, FetchGNews(cfg.GNewsAPIKey)...)
	}
	if cfg.MediaStackAPIKey != "" {
		all = append(all, FetchMediaStack(cfg.MediaStackAPIKey)...)
	}
	if cfg.CurrentsAPIKey != "" {
		all = append(all, FetchCurrents(cfg.CurrentsAPIKey)...)
	}
	// The joke providers are free and require no key.
	all = append(all, FetchJokes(cfg.JokeAPIURL)...)
	all = append(all, FetchOfficialJokes(cfg.OfficialJokeAPIURL)...)

	if len(all) > 0 {
		if err := repo.UpsertArticles(all); err != nil {
			return err
		}
		log.Printf("[ingest] upserted %d live articles", len(all))
	}
	return nil
}
