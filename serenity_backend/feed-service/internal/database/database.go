package database

import (
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Connect(dsn string, models ...interface{}) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("connect: %w", err)
	}
	if err := db.AutoMigrate(models...); err != nil {
		return nil, fmt.Errorf("migrate: %w", err)
	}
	log.Println("database connected and migrated")
	return db, nil
}
