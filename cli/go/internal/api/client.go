// Package api is a thin client for the DevTeam Rails server's /api/v1, using the
// per-user API token (Authorization: Bearer <token>).
package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Client struct {
	Server string
	Token  string
	HTTP   *http.Client
}

func New(server, token string) *Client {
	return &Client{
		Server: strings.TrimRight(server, "/"),
		Token:  token,
		HTTP:   &http.Client{Timeout: 30 * time.Second},
	}
}

type Project struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	RepoURL       string `json:"repo_url"`
	DefaultBranch string `json:"default_branch"`
}

type Ticket struct {
	ID         int    `json:"id"`
	Title      string `json:"title"`
	Status     string `json:"status"`
	Priority   string `json:"priority"`
	Kind       string `json:"kind"`
	BranchName string `json:"branch_name"`
	PRNumber   int    `json:"pr_number"`
	PRURL      string `json:"pr_url"`
	Project    struct {
		ID            int    `json:"id"`
		Name          string `json:"name"`
		RepoURL       string `json:"repo_url"`
		DefaultBranch string `json:"default_branch"`
	} `json:"project"`
	Assignee *struct {
		Name string `json:"name"`
	} `json:"assignee"`
}

func (c *Client) GetTicket(id int) (*Ticket, error) {
	var t Ticket
	if err := c.do("GET", fmt.Sprintf("/api/v1/tickets/%d", id), nil, &t); err != nil {
		return nil, err
	}
	return &t, nil
}

// UpdateTicket PATCHes the given ticket fields (wrapped in {ticket: {...}}).
func (c *Client) UpdateTicket(id int, fields map[string]any) (*Ticket, error) {
	body := map[string]any{"ticket": fields}
	var t Ticket
	if err := c.do("PATCH", fmt.Sprintf("/api/v1/tickets/%d", id), body, &t); err != nil {
		return nil, err
	}
	return &t, nil
}

func (c *Client) ListProjects() ([]Project, error) {
	var ps []Project
	if err := c.do("GET", "/api/v1/projects", nil, &ps); err != nil {
		return nil, err
	}
	return ps, nil
}

// ListTickets supports filters like {"assignee":"me","status":"open"}.
func (c *Client) ListTickets(filters map[string]string) ([]Ticket, error) {
	q := url.Values{}
	for k, v := range filters {
		if v != "" {
			q.Set(k, v)
		}
	}
	path := "/api/v1/tickets"
	if len(q) > 0 {
		path += "?" + q.Encode()
	}
	var ts []Ticket
	if err := c.do("GET", path, nil, &ts); err != nil {
		return nil, err
	}
	return ts, nil
}

func (c *Client) do(method, path string, body any, out any) error {
	if c.Server == "" {
		return fmt.Errorf("no server configured — set `server:` in %s", "~/.config/devteam/config.yml")
	}
	if c.Token == "" {
		return fmt.Errorf("no token configured — set `token:` in your config")
	}

	var rdr io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return err
		}
		rdr = bytes.NewReader(b)
	}

	req, err := http.NewRequest(method, c.Server+path, rdr)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("could not reach %s: %w", c.Server, err)
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)

	if resp.StatusCode >= 400 {
		return fmt.Errorf("%s %s → %d: %s", method, path, resp.StatusCode, strings.TrimSpace(string(data)))
	}
	if out != nil && len(data) > 0 {
		return json.Unmarshal(data, out)
	}
	return nil
}
