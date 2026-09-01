package handler

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"serenity-user-service/internal/config"
	"serenity-user-service/internal/model"
	"serenity-user-service/internal/repository"
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
	r.GET("/me", h.Me)
	r.PUT("/me", h.UpdateMe)
	r.GET("/top-readers", h.TopReaders)
	r.GET("/:id", h.GetProfile)
	r.POST("/:id/activity", h.IncrementActivity)
	r.POST("/:id/follow", h.Follow)
	r.DELETE("/:id/follow", h.Unfollow)
	r.GET("/:id/followers", h.Followers)
	r.GET("/:id/following", h.Following)
}

func (h *Handler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "user-service", "timestamp": time.Now().UTC().Format(time.RFC3339)})
}

func (h *Handler) Me(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	profile, err := h.repo.EnsureProfile(userID, c.GetHeader("X-User-Email"), c.GetHeader("X-User-Name"))
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load profile")
		return
	}
	c.JSON(http.StatusOK, profile)
}

func (h *Handler) UpdateMe(c *gin.Context) {
	userID := c.GetHeader("X-User-Id")
	if userID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if _, err := h.repo.EnsureProfile(userID, c.GetHeader("X-User-Email"), c.GetHeader("X-User-Name")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load profile")
		return
	}
	var body struct {
		Name      *string `json:"name"`
		Username  *string `json:"username"`
		Bio       *string `json:"bio"`
		AvatarURL *string `json:"avatarUrl"`
		IsPublic  *bool   `json:"isPublic"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		respondError(c, http.StatusBadRequest, "Invalid request body")
		return
	}
	updates := map[string]interface{}{}
	if body.Name != nil {
		updates["name"] = *body.Name
	}
	if body.Username != nil {
		updates["username"] = *body.Username
	}
	if body.Bio != nil {
		updates["bio"] = *body.Bio
	}
	if body.AvatarURL != nil {
		updates["avatar_url"] = *body.AvatarURL
	}
	if body.IsPublic != nil {
		updates["is_public"] = *body.IsPublic
	}
	if err := h.repo.UpdateProfile(userID, updates); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to update profile")
		return
	}
	profile, _ := h.repo.GetProfile(userID)
	c.JSON(http.StatusOK, profile)
}

func (h *Handler) TopReaders(c *gin.Context) {
	limit := limitQuery(c, 20)
	profiles, err := h.repo.TopReaders(limit)
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load top readers")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": profiles})
}

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.Param("id")
	profile, err := h.repo.GetProfile(userID)
	if err != nil {
		// Return a lightweight placeholder so visitor views never hard-fail.
		c.JSON(http.StatusOK, gin.H{
			"profile":     model.Profile{UserID: userID, Name: "Serenity User", IsPublic: true},
			"isFollowing": false,
		})
		return
	}
	requesterID := c.GetHeader("X-User-Id")
	isFollowing := false
	if requesterID != "" && requesterID != userID {
		isFollowing = h.repo.IsFollowing(requesterID, userID)
	}
	c.JSON(http.StatusOK, gin.H{"profile": profile, "isFollowing": isFollowing})
}

func (h *Handler) IncrementActivity(c *gin.Context) {
	userID := c.Param("id")
	var body struct {
		Type string `json:"type"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		respondError(c, http.StatusBadRequest, "Invalid request body")
		return
	}
	if _, err := h.repo.EnsureProfile(userID, "", ""); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load profile")
		return
	}
	if err := h.repo.IncrementActivity(userID, body.Type); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to record activity")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true})
}

func (h *Handler) Follow(c *gin.Context) {
	followerID := c.GetHeader("X-User-Id")
	followeeID := c.Param("id")
	if followerID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if _, err := h.repo.EnsureProfile(followerID, c.GetHeader("X-User-Email"), c.GetHeader("X-User-Name")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load profile")
		return
	}
	if _, err := h.repo.EnsureProfile(followeeID, "", ""); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load profile")
		return
	}
	if err := h.repo.Follow(followerID, followeeID); err != nil {
		respondError(c, http.StatusBadRequest, err.Error())
		return
	}
	go h.pushNotification(followeeID, "follow", "New follower", "Someone started following you.", followerID)
	c.JSON(http.StatusOK, gin.H{"success": true, "following": true})
}

func (h *Handler) Unfollow(c *gin.Context) {
	followerID := c.GetHeader("X-User-Id")
	if followerID == "" {
		respondError(c, http.StatusUnauthorized, "User id is required")
		return
	}
	if err := h.repo.Unfollow(followerID, c.Param("id")); err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to unfollow")
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "following": false})
}

func (h *Handler) Followers(c *gin.Context) {
	profiles, err := h.repo.ListFollowers(c.Param("id"))
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load followers")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": profiles})
}

func (h *Handler) Following(c *gin.Context) {
	profiles, err := h.repo.ListFollowing(c.Param("id"))
	if err != nil {
		respondError(c, http.StatusInternalServerError, "Failed to load following")
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": profiles})
}

func (h *Handler) pushNotification(userID, ntype, title, body, actorID string) {
	payload, _ := json.Marshal(map[string]string{
		"userId":  userID,
		"type":    ntype,
		"title":   title,
		"body":    body,
		"actorId": actorID,
	})
	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Post(h.cfg.NotificationServiceURL+"/notifications", "application/json", bytes.NewReader(payload))
	if err != nil {
		log.Printf("[notification] failed: %v", err)
		return
	}
	defer resp.Body.Close()
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
