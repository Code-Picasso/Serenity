package ingest

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"serenity-feed-service/internal/model"
)

const httpTimeout = 15 * time.Second

func httpGet(url string) ([]byte, error) {
	client := &http.Client{Timeout: httpTimeout}
	resp, err := client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("upstream returned status %d", resp.StatusCode)
	}
	return io.ReadAll(resp.Body)
}

// ---------- GNews ----------
type gnewsResponse struct {
	Articles []struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		Content     string `json:"content"`
		URL         string `json:"url"`
		Image       string `json:"image"`
		PublishedAt string `json:"publishedAt"`
		Source      struct {
			Name string `json:"name"`
		} `json:"source"`
	} `json:"articles"`
}

func FetchGNews(key string) []model.Article {
	url := fmt.Sprintf("https://gnews.io/api/v4/top-headlines?lang=en&max=20&token=%s", key)
	body, err := httpGet(url)
	if err != nil {
		log.Printf("[ingest] gnews failed: %v", err)
		return nil
	}
	var res gnewsResponse
	if err := json.Unmarshal(body, &res); err != nil {
		log.Printf("[ingest] gnews decode failed: %v", err)
		return nil
	}
	var out []model.Article
	for _, a := range res.Articles {
		out = append(out, model.Article{
			Source:      "gnews",
			SourceID:    a.URL,
			Title:       a.Title,
			Description: a.Description,
			Content:     a.Content,
			URL:         a.URL,
			ImageURL:    a.Image,
			Author:      a.Source.Name,
			Category:    "news",
			Topic:       classifyTopic(a.Title, a.Description, "news"),
			PublishedAt: parseTime(a.PublishedAt),
		})
	}
	return out
}

// ---------- Currents ----------
type currentsResponse struct {
	News []struct {
		ID          string   `json:"id"`
		Title       string   `json:"title"`
		Description string   `json:"description"`
		URL         string   `json:"url"`
		Image       string   `json:"image"`
		Author      string   `json:"author"`
		Published   string   `json:"published"`
		Category    []string `json:"category"`
	} `json:"news"`
}

func FetchCurrents(key string) []model.Article {
	url := fmt.Sprintf("https://api.currentsapi.services/v1/latest-news?apiKey=%s", key)
	body, err := httpGet(url)
	if err != nil {
		log.Printf("[ingest] currents failed: %v", err)
		return nil
	}
	var res currentsResponse
	if err := json.Unmarshal(body, &res); err != nil {
		log.Printf("[ingest] currents decode failed: %v", err)
		return nil
	}
	var out []model.Article
	for _, a := range res.News {
		cat := "news"
		if len(a.Category) > 0 {
			cat = normalizeCategory(a.Category[0])
		}
		out = append(out, model.Article{
			Source:      "currents",
			SourceID:    a.ID,
			Title:       a.Title,
			Description: a.Description,
			Content:     a.Description,
			URL:         a.URL,
			ImageURL:    a.Image,
			Author:      a.Author,
			Category:    cat,
			Topic:       classifyTopic(a.Title, a.Description, cat),
			PublishedAt: parseTime(a.Published),
		})
	}
	return out
}

// ---------- Joke API (jokeapi.dev) ----------
type jokeapiResponse struct {
	Jokes []struct {
		ID       int    `json:"id"`
		Category string `json:"category"`
		Type     string `json:"type"`
		Joke     string `json:"joke"`
		Setup    string `json:"setup"`
		Delivery string `json:"delivery"`
	} `json:"jokes"`
}

func FetchJokes(url string) []model.Article {
	body, err := httpGet(url + "?amount=10")
	if err != nil {
		log.Printf("[ingest] jokeapi failed: %v", err)
		return nil
	}
	var res jokeapiResponse
	if err := json.Unmarshal(body, &res); err != nil {
		log.Printf("[ingest] jokeapi decode failed: %v", err)
		return nil
	}
	var out []model.Article
	for _, j := range res.Jokes {
		content := j.Joke
		if content == "" {
			content = j.Setup + " " + j.Delivery
		}
		out = append(out, model.Article{
			Source:      "jokeapi",
			SourceID:    fmt.Sprintf("jokeapi-%d", j.ID),
			Title:       j.Setup,
			Description: j.Delivery,
			Content:     content,
			Category:    "jokes",
			Topic:       jokeTopic(j.Category),
			PublishedAt: time.Now().UTC(),
		})
	}
	return out
}

// ---------- Official Joke API ----------
type officialJoke struct {
	ID        int    `json:"id"`
	Type      string `json:"type"`
	Setup     string `json:"setup"`
	Punchline string `json:"punchline"`
}

func FetchOfficialJokes(url string) []model.Article {
	body, err := httpGet(url)
	if err != nil {
		log.Printf("[ingest] official-joke-api failed: %v", err)
		return nil
	}
	var jokes []officialJoke
	if err := json.Unmarshal(body, &jokes); err != nil {
		var single officialJoke
		if err2 := json.Unmarshal(body, &single); err2 != nil {
			log.Printf("[ingest] official-joke-api decode failed: %v", err)
			return nil
		}
		jokes = []officialJoke{single}
	}
	var out []model.Article
	for _, j := range jokes {
		out = append(out, model.Article{
			Source:      "officialjoke",
			SourceID:    fmt.Sprintf("officialjoke-%d", j.ID),
			Title:       j.Setup,
			Description: j.Punchline,
			Content:     j.Setup + " " + j.Punchline,
			Category:    "jokes",
			Topic:       "dad-jokes",
			PublishedAt: time.Now().UTC(),
		})
	}
	return out
}

// ---------- Mock content (works with no API keys) ----------
func MockArticles() []model.Article {
	now := time.Now().UTC()
	mk := func(source, id, title, desc, category, topic string, offset int) model.Article {
		return model.Article{
			Source:      source,
			SourceID:    id,
			Title:       title,
			Description: desc,
			Content:     desc,
			URL:         "https://example.com/" + id,
			ImageURL:    "",
			Author:      "Serenity",
			Category:    category,
			Topic:       topic,
			PublishedAt: now.Add(-time.Duration(offset) * time.Hour),
		}
	}
	return []model.Article{
		mk("mock", "world-1", "City unveils plan for greener public transport", "A new initiative will electrify the bus fleet and add protected cycle lanes across the city.", "news", "world", 1),
		mk("mock", "politics-1", "Election debate turns to the economy and housing", "Candidates clashed over tax policy and housing affordability in the first televised debate.", "news", "politics", 2),
		mk("mock", "business-1", "Global markets rally as tech earnings beat expectations", "Stocks climbed today as major technology companies reported quarterly results ahead of forecasts.", "business", "business", 3),
		mk("mock", "tech-1", "Understanding microservices: a practical guide", "A look at how breaking an app into services improves scalability and team velocity.", "technology", "technology", 4),
		mk("mock", "tech-2", "The rise of on-device machine learning", "Phones are getting smarter without the cloud thanks to smaller, faster models.", "technology", "technology", 5),
		mk("mock", "science-1", "Astronomers spot a rare double-ring galaxy", "New imaging reveals structure that challenges existing formation models.", "science", "science", 6),
		mk("mock", "health-1", "Five simple habits that improve daily focus", "Small, sustainable routines can have an outsized effect on mental clarity.", "health", "health", 7),
		mk("mock", "education-1", "Schools adopt a new hands-on science curriculum", "Students will spend more time in labs under a revised national curriculum.", "news", "education", 8),
		mk("mock", "football-1", "Local club seals a dramatic cup final win", "A stoppage-time goal completed a stunning comeback in front of a packed stadium.", "sports", "football", 9),
		mk("mock", "basketball-1", "Championship decider goes down to the wire", "The title was decided in the final seconds as the underdogs held their nerve.", "sports", "basketball", 10),
		mk("mock", "tennis-1", "Grand slam preview: top seeds to watch", "The draw is set and the favourites look sharp ahead of the opening rounds.", "sports", "tennis", 11),
		mk("mock", "motorsport-1", "Title fight heats up as F1 heads to the night race", "The championship battle remains wide open with three races to go.", "sports", "motorsport", 12),
		mk("mock", "cricket-1", "World cup squad announced ahead of the tournament", "Selectors balanced experience with youth in a bold final squad.", "sports", "cricket", 13),
		mk("mock", "movies-1", "The most anticipated releases this season", "From blockbusters to indie gems, here is what critics are excited about.", "entertainment", "movies", 14),
		mk("mock", "music-1", "New album roundup: the best drops this week", "Our critics pick the standout records you need to hear right now.", "entertainment", "music", 15),
		mk("mock", "gaming-1", "Indie gaming boom continues into the new year", "Small studios are punching above their weight with breakout hits.", "entertainment", "gaming", 16),
		mk("mock", "celebrity-1", "Actor reflects on a decade in the spotlight", "A candid interview on fame, failure and finding balance.", "entertainment", "celebrity", 17),
		mk("mock", "community-1", "Why community beats follower count", "Meaningful connection is becoming the currency of the modern internet.", "social", "community", 18),
		mk("mock", "culture-1", "How street food shaped a city's identity", "Vendors tell the story of a city through its most beloved dishes.", "social", "culture", 19),
		mk("mock", "joke-1", "Why did the developer go broke?", "Because they used up all their cache.", "jokes", "jokes", 2),
		mk("mock", "pun-1", "I told my computer I needed a break.", "Now it won't stop sending me KitKat ads.", "jokes", "puns", 3),
		mk("mock", "dark-1", "My humor is like a dark room.", "Nothing can light it up.", "jokes", "dark-humor", 4),
		mk("mock", "yomama-1", "Yo mama is so old", "her memory is in black and white.", "jokes", "yo-mama", 5),
		mk("mock", "dadjoke-1", "I'm reading a book about anti-gravity.", "It's impossible to put down.", "jokes", "dad-jokes", 6),
		mk("mock", "knock-1", "Knock knock. Who's there? Lettuce.", "Lettuce who? Lettuce in, it's cold out here!", "jokes", "knock-knock", 7),
	}
}

func parseTime(s string) time.Time {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t
	}
	if t, err := time.Parse("2006-01-02 15:04:05", s); err == nil {
		return t
	}
	return time.Now().UTC()
}

func normalizeCategory(s string) string {
	switch s {
	case "technology", "tech", "science":
		return "technology"
	case "business", "finance", "economy":
		return "business"
	case "sports", "sport":
		return "sports"
	case "health", "wellness":
		return "health"
	case "entertainment", "culture", "arts":
		return "entertainment"
	default:
		return "news"
	}
}

// classifyTopic assigns a fine-grained interest label (football, politics,
// dark-humor, …) based on the content text, falling back to the broad category.
func classifyTopic(title, description, category string) string {
	text := strings.ToLower(title + " " + description)
	switch {
	case containsAny(text, "football", "soccer", "premier league", "champions league", "world cup"):
		return "football"
	case containsAny(text, "basketball", "nba"):
		return "basketball"
	case containsAny(text, "tennis", "grand slam", "wimbledon"):
		return "tennis"
	case containsAny(text, "formula one", "formula 1", "motorsport", "grand prix"):
		return "motorsport"
	case containsAny(text, "cricket", "ipl"):
		return "cricket"
	case containsAny(text, "politics", "election", "government", "president", "senate", "parliament"):
		return "politics"
	case containsAny(text, "movie", "film", "hollywood", "cinema", "box office"):
		return "movies"
	case containsAny(text, "music", "album", "concert"):
		return "music"
	case containsAny(text, "gaming", "esports", "playstation", "xbox", "nintendo"):
		return "gaming"
	case containsAny(text, "celebrity", "actor", "actress"):
		return "celebrity"
	case containsAny(text, "community", "culture"):
		return "culture"
	}
	switch category {
	case "news":
		return "world"
	case "social":
		return "community"
	default:
		return category
	}
}

func containsAny(text string, keywords ...string) bool {
	for _, k := range keywords {
		if strings.Contains(text, k) {
			return true
		}
	}
	return false
}

// jokeTopic maps a jokeapi.dev category ("dark", "pun", …) to a Serenity topic.
func jokeTopic(category string) string {
	switch strings.ToLower(category) {
	case "dark":
		return "dark-humor"
	case "pun":
		return "puns"
	default:
		return "jokes"
	}
}
