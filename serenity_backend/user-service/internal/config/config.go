package config

import "os"

type Config struct {
	Port                   string
	DatabaseURL            string
	NotificationServiceURL string
}

func Load() Config {
	return Config{
		Port:                   getEnv("PORT", "8006"),
		DatabaseURL:            getEnv("DATABASE_URL", "postgresql://serenity:serenity@localhost:5436/user?sslmode=disable"),
		NotificationServiceURL: getEnv("NOTIFICATION_SERVICE_URL", "http://notification-service:8007"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
