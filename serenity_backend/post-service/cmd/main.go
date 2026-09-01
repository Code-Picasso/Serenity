package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"serenity-post-service/internal/config"
	"serenity-post-service/internal/database"
	"serenity-post-service/internal/handler"
	"serenity-post-service/internal/model"
	"serenity-post-service/internal/repository"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL, &model.Post{}, &model.SavedItem{}, &model.Like{})
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	repo := repository.New(db)
	router := gin.Default()
	h := handler.New(repo, cfg)
	h.Register(router)

	log.Printf("Post service listening on :%s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
