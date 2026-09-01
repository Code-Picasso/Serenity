package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"serenity-notification-service/internal/model"
	"serenity-notification-service/internal/repository"
)

type Handler struct {
	repo *repository.Repository
}

func New(repo *repository.Repository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Register(r *gin.Engine) {
	r.GET("/health", h.Health)
	r.GET("/", h.List)
	r.GET("/unread-count", h.UnreadCount)
	r.POST("/", h.Create)
	r.PUT("/read-all", h.MarkAllRead)
	r.PUT("/:id/read", h.MarkRead)
	r.DELETE("/:id", h.Delete)
}

func (h *Handler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "notification-service", "timestamp": time.Now().UTC().Format(time.RFC3339)})
}

func (h *Handler) List(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	page := intQuery(c, "page", 1)
	limit := intQuery(c, "limit", 20)
	items, total, err := h.repo.List(userID, page, limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load notifications")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items, "page": page, "limit": limit, "total": total})
}

func (h *Handler) UnreadCount(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{"count": 0})
		return
	}
	count, err := h.repo.UnreadCount(userID)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load unread count")
		return
	}
	c.JSON(http.StatusOK, gin.H{"count": count})
}

func (h *Handler) Create(c *gin.Context) {
	var body struct {
		UserID  string `json:"userId"`
		Type    string `json:"type"`
		Title   string `json:"title"`
		Body    string `json:"body"`
		ActorID string `json:"actorId"`
		Data    string `json:"data"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		respondError(c, http.StatusBadRequest, "Invalid request body")
		return
	}
	if body.UserID == "" {
		respondError(c, http.StatusBadRequest, "userId is required")
		return
	}
	n := &model.Notification{
		UserID:  body.UserID,
		Type:    body.Type,
		Title:   body.Title,
		Body:    body.Body,
		ActorID: body.ActorID,
		Data:    body.Data,
	}
	if err := h.repo.Create(n); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to create notification")
		return
	}
	c.JSON(http.StatusCreated, n)
}

func (h *Handler) MarkRead(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if err := h.repo.MarkRead(c.Param("id"), userID); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to mark read")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) MarkAllRead(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if err := h.repo.MarkAllRead(userID); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to mark all read")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) Delete(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if err := h.repo.Delete(c.Param("id"), userID); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to delete notification")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
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

func respondError(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"error": message})
}
