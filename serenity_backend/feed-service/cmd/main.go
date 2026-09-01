package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"serenity-feed-service/internal/config"
	"serenity-feed-service/internal/database"
	"serenity-feed-service/internal/handler"
	"serenity-feed-service/internal/ingest"
	"serenity-feed-service/internal/model"
	"serenity-feed-service/internal/repository"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL, &model.Article{}, &model.UserInterest{}, &model.SavedArticle{})
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	repo := repository.New(db)
	ingest.Start(db, cfg)

	router := gin.Default()
	h := handler.New(repo, cfg)
	h.Register(router)

	log.Printf("Feed service listening on :%s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
