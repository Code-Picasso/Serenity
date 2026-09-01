package main

import (
	"log"

	"github.com/gin-gonic/gin"

	"serenity-notification-service/internal/config"
	"serenity-notification-service/internal/database"
	"serenity-notification-service/internal/handler"
	"serenity-notification-service/internal/model"
	"serenity-notification-service/internal/repository"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL, &model.Notification{})
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	repo := repository.New(db)
	router := gin.Default()
	h := handler.New(repo)
	h.Register(router)

	log.Printf("Notification service listening on :%s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server: %v", err)
	}
}
