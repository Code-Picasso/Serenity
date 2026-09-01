package config

import "os"

type Config struct {
	Port           string
	DatabaseURL    string
	UploadDir      string
	UserServiceURL string
}

func Load() Config {
	return Config{
		Port:           getEnv("PORT", "8005"),
		DatabaseURL:    getEnv("DATABASE_URL", "postgresql://serenity:serenity@localhost:5435/post?sslmode=disable"),
		UploadDir:      getEnv("UPLOAD_DIR", "uploads"),
		UserServiceURL: getEnv("USER_SERVICE_URL", "http://user-service:8006"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
