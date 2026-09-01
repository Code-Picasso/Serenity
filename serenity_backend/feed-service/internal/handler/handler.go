package handler

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"serenity-feed-service/internal/config"
	"serenity-feed-service/internal/repository"
)

type TopicSection struct {
	Name   string   `json:"name"`
	Topics []string `json:"topics"`
}

// TopicSections is the curated interest catalog surfaced by GET /topics.
var TopicSections = []TopicSection{
	{Name: "News", Topics: []string{"world", "politics", "business", "technology", "science", "health", "education"}},
	{Name: "Sports", Topics: []string{"football", "basketball", "tennis", "motorsport", "cricket"}},
	{Name: "Entertainment", Topics: []string{"movies", "music", "gaming", "celebrity"}},
	{Name: "Social", Topics: []string{"community", "culture"}},
	{Name: "Humor", Topics: []string{"jokes", "puns", "dark-humor", "yo-mama", "dad-jokes", "knock-knock"}},
}

// AllTopics is the flattened list of every selectable interest.
var AllTopics = func() []string {
	var out []string
	for _, s := range TopicSections {
		out = append(out, s.Topics...)
	}
	return out
}()

type Handler struct {
	repo *repository.Repository
	cfg  config.Config
}

func New(repo *repository.Repository, cfg config.Config) *Handler {
	return &Handler{repo: repo, cfg: cfg}
}

func (h *Handler) Register(r *gin.Engine) {
	r.GET("/health", h.Health)
	r.GET("/", h.Feed)
	r.GET("/articles/:id", h.Article)
	r.POST("/articles/:id/read", h.Read)
	r.POST("/articles/:id/save", h.SaveArticle)
	r.DELETE("/articles/:id/save", h.UnsaveArticle)
	r.GET("/saved", h.ListSavedArticles)
	r.GET("/search", h.Search)
	r.GET("/topics", h.Topics)
	r.GET("/interests", h.GetInterests)
	r.PUT("/interests", h.PutInterests)
}

func (h *Handler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "feed-service", "timestamp": time.Now().UTC().Format(time.RFC3339)})
}

func (h *Handler) Feed(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	page := intQuery(c, "page", 1)
	limit := limitQuery(c, 20)
	topic := c.Query("topic")

	interests, _ := h.repo.GetInterests(userID)
	items, total, err := h.repo.ListFeed(interests, topic, page, limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load feed")
		return
	}
	// Fall back to the general feed when a personalised filter yields nothing yet.
	if len(items) == 0 && topic == "" && len(interests) > 0 {
		items, total, err = h.repo.ListFeed(nil, "", page, limit)
		if err != nil {
			respondError(c, http.StatusInternalServerError, "Failed to load feed")
			return
		}
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "page": page, "limit": limit, "total": total})
}

func (h *Handler) Article(c *gin.Context) {
	article, err := h.repo.GetArticle(c.Param("id"))
	if err != nil {
		respondError(c, http.StatusNotFound, "Article not found")
		return
	}
	c.JSON(http.StatusOK, article)
}

func (h *Handler) Read(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if _, err := h.repo.GetArticle(c.Param("id")); err != nil {
		respondError(c, http.StatusNotFound, "Article not found")
		return
	}
	if userID != "" {
		go recordActivity(h.cfg.UserServiceURL, userID, "read")
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) SaveArticle(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if err := h.repo.SaveArticle(userID, c.Param("id")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to save article")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) UnsaveArticle(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if err := h.repo.UnsaveArticle(userID, c.Param("id")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to unsave article")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) ListSavedArticles(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{"items": []interface{}{}})
		return
	}
	items, err := h.repo.ListSavedArticles(userID)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load saved articles")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) Search(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		respondError(c, http.StatusBadRequest, "q is required")
		return
	}
	page := intQuery(c, "page", 1)
	limit := limitQuery(c, 20)
	items, total, err := h.repo.Search(q, page, limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Search failed")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "page": page, "limit": limit, "total": total})
}

func (h *Handler) Topics(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"sections": TopicSections, "topics": AllTopics})
}

func (h *Handler) GetInterests(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{"topics": []string{}})
		return
	}
	topics, err := h.repo.GetInterests(userID)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load interests")
		return
	}
	c.JSON(http.StatusOK, gin.H{"topics": topics})
}

func (h *Handler) PutInterests(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	var body struct {
		Topics []string `json:"topics"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		respondError(c, http.StatusBadRequest, "Invalid request body")
		return
	}
	if err := h.repo.ReplaceInterests(userID, body.Topics); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to save interests")
		return
	}
	c.JSON(http.StatusOK, gin.H{"topics": body.Topics})
}

func intQuery(c *gin.Context, key string, fallback int) int {
	v := c.Query(key)
	if v == "" {
		return fallback
	}
	n, err := strconv.Atoi(v)
	if err != nil || n <= 0 {
		return fallback
	}
	return n
}

// maxPageSize bounds the number of items a client may request per page.
const maxPageSize = 100

func limitQuery(c *gin.Context, fallback int) int {
	n := intQuery(c, "limit", fallback)
	if n > maxPageSize {
		return maxPageSize
	}
	return n
}

func respondError(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"error": errorType(status), "message": message})
}

// errorType maps an HTTP status to a stable error code matching the Node
// services so clients see one error shape across the whole backend.
func errorType(status int) string {
	switch status {
	case http.StatusBadRequest:
		return "ValidationError"
	case http.StatusUnauthorized:
		return "UnauthorizedError"
	case http.StatusForbidden:
		return "ForbiddenError"
	case http.StatusNotFound:
		return "NotFoundError"
	case http.StatusConflict:
		return "ConflictError"
	default:
		return "Internal Server Error"
	}
}

func recordActivity(userServiceURL, userID, activityType string) {
	payload, _ := json.Marshal(map[string]string{"type": activityType})
	url := userServiceURL + "/users/" + userID + "/activity"
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Post(url, "application/json", bytes.NewReader(payload))
	if err != nil {
		log.Printf("[activity] failed: %v", err)
		return
	}
	defer resp.Body.Close()
}
