package handler

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"serenity-post-service/internal/config"
	"serenity-post-service/internal/model"
	"serenity-post-service/internal/repository"
)

type Handler struct {
	repo *repository.Repository
	cfg  config.Config
}

func New(repo *repository.Repository, cfg config.Config) *Handler {
	return &Handler{repo: repo, cfg: cfg}
}

func (h *Handler) Register(r *gin.Engine) {
	r.GET("/health", h.Health)
	r.GET("/", h.ListPosts)
	r.POST("/", h.CreatePost)
	r.POST("/upload", h.UploadImage)
	r.GET("/saved", h.ListSaved)
	r.GET("/reshared", h.ListReshared)
	r.GET("/users/:userId/posts", h.ListUserPosts)
	r.GET("/:id", h.GetPost)
	r.DELETE("/:id", h.DeletePost)
	r.POST("/:id/like", h.ToggleLike)
	r.POST("/:id/reshare", h.Reshare)
	r.POST("/:id/save", h.Save)
	r.DELETE("/:id/save", h.Unsave)
}

func (h *Handler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "post-service", "timestamp": time.Now().UTC().Format(time.RFC3339)})
}

func (h *Handler) ListPosts(c *gin.Context) {
	page := intQuery(c, "page", 1)
	limit := limitQuery(c, 20)
	items, total, err := h.repo.ListPosts(page, limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load posts")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "page": page, "limit": limit, "total": total})
}

func (h *Handler) ListUserPosts(c *gin.Context) {
	page := intQuery(c, "page", 1)
	limit := limitQuery(c, 20)
	items, err := h.repo.ListPostsByUser(c.Param("userId"), page, limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load posts")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) GetPost(c *gin.Context) {
	post, err := h.repo.GetPost(c.Param("id"))
	if err != nil {
		respondError(c, http.StatusNotFound, "Post not found")
		return
	}
	if userID := c.GetHeader("X-User-Id"); userID != "" {
		go recordActivity(h.cfg.UserServiceURL, userID, "read")
	}
	c.JSON(http.StatusOK, post)
}

func (h *Handler) CreatePost(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	var body struct {
		Text     string `json:"text"`
		ImageURL string `json:"imageUrl"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		respondError(c, http.StatusBadRequest, "Invalid request body")
		return
	}
	if body.Text == "" && body.ImageURL == "" {
		respondError(c, http.StatusBadRequest, "text or imageUrl is required")
		return
	}
	post := &model.Post{UserID: userID, Text: body.Text, ImageURL: body.ImageURL}
	if err := h.repo.CreatePost(post); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to create post")
		return
	}
	go recordActivity(h.cfg.UserServiceURL, userID, "post")
	c.JSON(http.StatusCreated, post)
}

func (h *Handler) UploadImage(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		respondError(c, http.StatusBadRequest, "image file is required")
		return
	}
	if err := os.MkdirAll(h.cfg.UploadDir, 0o755); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to create upload dir")
		return
	}
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("image-%d-%d%s", time.Now().UnixMilli(), time.Now().Nanosecond()%100000, ext)
	dst := filepath.Join(h.cfg.UploadDir, filename)
	if err := c.SaveUploadedFile(file, dst); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to save image")
		return
	}
	c.JSON(http.StatusCreated, gin.H{"imageUrl": "/posts/uploads/" + filename})
}

func (h *Handler) DeletePost(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if err := h.repo.DeletePost(c.Param("id"), userID); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to delete post")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) ToggleLike(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	liked, err := h.repo.ToggleLike(userID, c.Param("id"))
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to update like")
		return
	}
	c.JSON(http.StatusOK, gin.H{"liked": liked})
}

func (h *Handler) Reshare(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	original, err := h.repo.GetPost(c.Param("id"))
	if err != nil {
		respondError(c, http.StatusNotFound, "Post not found")
		return
	}
	reshare := &model.Post{
		UserID:    userID,
		Text:      original.Text,
		ImageURL:  original.ImageURL,
		ReshareID: &original.ID,
	}
	if err := h.repo.CreatePost(reshare); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to reshare")
		return
	}
	go recordActivity(h.cfg.UserServiceURL, userID, "share")
	c.JSON(http.StatusCreated, reshare)
}

func (h *Handler) Save(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if err := h.repo.SavePost(userID, c.Param("id")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to save post")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) Unsave(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if err := h.repo.UnsavePost(userID, c.Param("id")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to unsave post")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) ListSaved(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{"items": []model.Post{}})
		return
	}
	items, err := h.repo.ListSavedPosts(userID)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load saved posts")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) ListReshared(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{"items": []model.Post{}})
		return
	}
	items, err := h.repo.ListReshared(userID)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load reshared posts")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
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

// IsNotFound is a small helper used by tests.
func IsNotFound(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound)
}
