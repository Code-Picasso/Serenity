package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port               string
	DatabaseURL        string
	GNewsAPIKey        string
	CurrentsAPIKey     string
	JokeAPIURL         string
	OfficialJokeAPIURL string
	IngestIntervalMin  int
	MockMode           bool
	UserServiceURL     string
}

func Load() Config {
	return Config{
		Port:               getEnv("PORT", "8004"),
		DatabaseURL:        getEnv("DATABASE_URL", "postgresql://serenity:serenity@localhost:5434/feed?sslmode=disable"),
		GNewsAPIKey:        os.Getenv("GNEWS_API_KEY"),
		CurrentsAPIKey:     os.Getenv("CURRENTS_API_KEY"),
		JokeAPIURL:         getEnv("JOKE_API_URL", "https://v2.jokeapi.dev/joke/Any"),
		OfficialJokeAPIURL: getEnv("OFFICIAL_JOKE_API_URL", "https://official-joke-api.appspot.com/random_joke"),
		IngestIntervalMin:  getIntEnv("INGEST_INTERVAL_MINUTES", 30),
		MockMode:           getBoolEnv("MOCK_MODE", true),
		UserServiceURL:     getEnv("USER_SERVICE_URL", "http://user-service:8006"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getIntEnv(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func getBoolEnv(key string, fallback bool) bool {
	if v := os.Getenv(key); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return fallback
}
