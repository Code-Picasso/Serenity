package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"serenity-user-service/internal/config"
	"serenity-user-service/internal/database"
	"serenity-user-service/internal/handler"
	"serenity-user-service/internal/model"
	"serenity-user-service/internal/repository"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL, &model.Profile{}, &model.Follow{})
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	repo := repository.New(db)
	router := gin.Default()
	h := handler.New(repo, cfg)
	h.Register(router)

	log.Printf("User service listening on :%s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
