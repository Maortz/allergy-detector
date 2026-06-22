# Android Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `Maortz/android-builder` — a Go CLI that triggers Android APK builds on GitHub Actions, downloads the artifact, installs via adb, and runs a Flutter hot-reload dev session.

**Architecture:** Mirrors `MobAI-App/ios-builder`. Cobra CLI with `builder android build` (trigger GHA → poll artifact → download APK to `dist/`) and `builder dev flutter` (adb install → flutter attach subprocess + file watcher for hot-reload). No MobAI dependency — Android uses adb directly.

**Tech Stack:** Go 1.22, Cobra, go-keyring, golang.org/x/term, github.com/google/uuid, github.com/manifoldco/promptui

---

## File Map

```
Maortz/android-builder/
├── cmd/builder/
│   ├── main.go          # rootCmd.Execute()
│   ├── root.go          # rootCmd + loadConfig() + getGitHubClient() helpers
│   ├── init.go          # builder init command
│   ├── auth.go          # builder auth github command
│   ├── android.go       # builder android build command
│   └── flutter.go       # builder dev flutter command
├── internal/
│   ├── auth/auth.go             # GetToken / SetToken (keyring → file fallback)
│   ├── build/
│   │   ├── coordinator.go       # trigger → poll → download APK
│   │   └── progress.go          # phase/spinner UI
│   ├── config/
│   │   ├── types.go             # Config, AndroidConfig, FlutterConfig, WatchConfig
│   │   ├── config.go            # Manager.Load / Manager.Save
│   │   └── config_test.go       # save/load/validate tests
│   ├── github/
│   │   ├── types.go             # WorkflowRun, Artifact
│   │   ├── client.go            # Client, do(), decode(), progressReader
│   │   └── workflow.go          # TriggerWorkflow, PollForWorkflowStart, PollForArtifact, Download
│   ├── dev/
│   │   ├── session.go           # adb device select, install, launch, FindAPK
│   │   ├── flutter.go           # FlutterHandler: flutter attach subprocess + hot-reload
│   │   ├── watcher.go           # file watcher → writes 'r\n' to flutter attach stdin
│   │   └── watcher_test.go      # watcher detects change, ignores pattern
│   └── workflow/
│       ├── templates.go                   # //go:embed + GetWorkflowTemplate()
│       └── templates/android-build.yml   # GHA workflow
├── go.mod
├── Makefile
├── install.sh
└── README.md
```

---

### Task 1: Create repo + go.mod + skeleton

**Files:**
- Create: `go.mod`
- Create: `cmd/builder/main.go`
- Create: `Makefile`

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create Maortz/android-builder --public --description "Build Android apps remotely using GitHub Actions"
gh repo clone Maortz/android-builder
cd android-builder
```

- [ ] **Step 2: Create directory structure**

```bash
mkdir -p cmd/builder internal/auth internal/build internal/config \
         internal/github internal/dev internal/workflow/templates
```

- [ ] **Step 3: Write go.mod**

```
module github.com/Maortz/android-builder

go 1.22
```

- [ ] **Step 4: Write cmd/builder/main.go**

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
```

- [ ] **Step 5: Write Makefile**

```makefile
.PHONY: build test lint clean install

build:
	go build -o builder ./cmd/builder

test:
	go test ./...

clean:
	rm -f builder

install: build
	cp builder /usr/local/bin/builder
```

- [ ] **Step 6: Install dependencies**

```bash
go get github.com/spf13/cobra@v1.8.0
go get github.com/manifoldco/promptui@v0.9.0
go get github.com/google/uuid@v1.6.0
go get github.com/zalando/go-keyring@v0.2.5
go get golang.org/x/term@v0.22.0
go mod tidy
```

- [ ] **Step 7: Commit**

```bash
git add go.mod go.sum cmd/ Makefile
git commit -m "feat: repo scaffold, go.mod, main entry"
```

---

### Task 2: Config types + load/save + tests (TDD)

**Files:**
- Create: `internal/config/types.go`
- Create: `internal/config/config.go`
- Create: `internal/config/config_test.go`

- [ ] **Step 1: Write failing tests**

`internal/config/config_test.go`:
```go
package config_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/Maortz/android-builder/internal/config"
)

func TestSaveAndLoad(t *testing.T) {
	dir := t.TempDir()
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	mgr := config.NewManager()
	cfg := &config.Config{
		Project:  "test-app",
		Platform: "android",
		GitHub:   config.GitHubConfig{Owner: "acme", Repo: "app"},
		Android:  config.AndroidConfig{BuildType: "debug"},
	}
	if err := mgr.Save(cfg); err != nil {
		t.Fatalf("Save: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "builder.json")); err != nil {
		t.Fatalf("builder.json not created")
	}
	loaded, err := mgr.Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if loaded.Project != "test-app" {
		t.Errorf("Project: got %q want %q", loaded.Project, "test-app")
	}
	if loaded.Android.BuildType != "debug" {
		t.Errorf("BuildType: got %q want debug", loaded.Android.BuildType)
	}
}

func TestLoadNotFound(t *testing.T) {
	dir := t.TempDir()
	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	_, err := config.NewManager().Load()
	if err != config.ErrConfigNotFound {
		t.Errorf("want ErrConfigNotFound, got %v", err)
	}
}

func TestValidate(t *testing.T) {
	cases := []struct {
		name    string
		cfg     config.Config
		wantErr bool
	}{
		{"valid", config.Config{Project: "x", GitHub: config.GitHubConfig{Owner: "a", Repo: "b"}}, false},
		{"no project", config.Config{GitHub: config.GitHubConfig{Owner: "a", Repo: "b"}}, true},
		{"no owner", config.Config{Project: "x", GitHub: config.GitHubConfig{Repo: "b"}}, true},
		{"no repo", config.Config{Project: "x", GitHub: config.GitHubConfig{Owner: "a"}}, true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			err := c.cfg.Validate()
			if (err != nil) != c.wantErr {
				t.Errorf("Validate() = %v, wantErr %v", err, c.wantErr)
			}
		})
	}
}
```

- [ ] **Step 2: Run tests — expect compile failure**

```bash
go test ./internal/config/...
```
Expected: `cannot find package`

- [ ] **Step 3: Write internal/config/types.go**

```go
package config

import "errors"

var ErrConfigNotFound = errors.New("builder.json not found")

type Config struct {
	Project  string        `json:"project"`
	Platform string        `json:"platform"`
	GitHub   GitHubConfig  `json:"github"`
	Android  AndroidConfig `json:"android,omitempty"`
	Flutter  FlutterConfig `json:"flutter,omitempty"`
}

type GitHubConfig struct {
	Owner string `json:"owner"`
	Repo  string `json:"repo"`
}

type AndroidConfig struct {
	BuildType   string `json:"buildType,omitempty"`
	Flavor      string `json:"flavor,omitempty"`
	PackageName string `json:"packageName,omitempty"`
}

type FlutterConfig struct {
	Version string      `json:"version,omitempty"`
	Watch   WatchConfig `json:"watch,omitempty"`
}

type WatchConfig struct {
	Dirs     []string `json:"dirs,omitempty"`
	Patterns []string `json:"patterns,omitempty"`
	Ignore   []string `json:"ignore,omitempty"`
	Debounce int      `json:"debounce,omitempty"`
}

type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string {
	return "config: " + e.Field + ": " + e.Message
}

func (c *Config) Validate() error {
	if c.Project == "" {
		return &ValidationError{Field: "project", Message: "required"}
	}
	if c.GitHub.Owner == "" {
		return &ValidationError{Field: "github.owner", Message: "required"}
	}
	if c.GitHub.Repo == "" {
		return &ValidationError{Field: "github.repo", Message: "required"}
	}
	return nil
}
```

- [ ] **Step 4: Write internal/config/config.go**

```go
package config

import (
	"encoding/json"
	"errors"
	"os"
)

const configFile = "builder.json"

type Manager struct{}

func NewManager() *Manager { return &Manager{} }

func (m *Manager) Load() (*Config, error) {
	data, err := os.ReadFile(configFile)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, ErrConfigNotFound
		}
		return nil, err
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func (m *Manager) Save(cfg *Config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(configFile, append(data, '\n'), 0644)
}
```

- [ ] **Step 5: Run tests — expect PASS**

```bash
go test ./internal/config/... -v
```
Expected: `PASS` for all 3 test functions.

- [ ] **Step 6: Commit**

```bash
git add internal/config/
git commit -m "feat: config types, load/save, validation"
```

---

### Task 3: GitHub auth storage

**Files:**
- Create: `internal/auth/auth.go`

- [ ] **Step 1: Write internal/auth/auth.go**

```go
package auth

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/zalando/go-keyring"
)

const (
	serviceName = "android-builder"
	accountName = "github-token"
)

var tokenFile = filepath.Join(homeDir(), ".config", "android-builder", "token")

func homeDir() string {
	if h, err := os.UserHomeDir(); err == nil {
		return h
	}
	return os.Getenv("HOME")
}

func GetToken() (string, error) {
	token, err := keyring.Get(serviceName, accountName)
	if err == nil && token != "" {
		return token, nil
	}
	data, err := os.ReadFile(tokenFile)
	if err != nil {
		return "", errors.New("not authenticated")
	}
	token = strings.TrimSpace(string(data))
	if token == "" {
		return "", errors.New("not authenticated")
	}
	return token, nil
}

func SetToken(token string) error {
	if err := keyring.Set(serviceName, accountName, token); err == nil {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(tokenFile), 0700); err != nil {
		return err
	}
	return os.WriteFile(tokenFile, []byte(token), 0600)
}

func DeleteToken() {
	_ = keyring.Delete(serviceName, accountName)
	_ = os.Remove(tokenFile)
}
```

- [ ] **Step 2: Verify compile**

```bash
go build ./internal/auth/...
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add internal/auth/
git commit -m "feat: GitHub token storage (keyring + file fallback)"
```

---

### Task 4: GitHub API client

**Files:**
- Create: `internal/github/types.go`
- Create: `internal/github/client.go`
- Create: `internal/github/workflow.go`

- [ ] **Step 1: Write internal/github/types.go**

```go
package github

import "time"

type WorkflowRun struct {
	ID        int64     `json:"id"`
	Status    string    `json:"status"`
	HTMLURL   string    `json:"html_url"`
	CreatedAt time.Time `json:"created_at"`
}

type Artifact struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

type listRunsResponse struct {
	WorkflowRuns []WorkflowRun `json:"workflow_runs"`
}

type listArtifactsResponse struct {
	Artifacts []Artifact `json:"artifacts"`
}
```

- [ ] **Step 2: Write internal/github/client.go**

```go
package github

import (
	"context"
	"fmt"
	"io"
	"net/http"
)

const baseURL = "https://api.github.com"

type Client struct {
	token  string
	client *http.Client
}

func NewClient(token string) *Client {
	return &Client{token: token, client: &http.Client{}}
}

func (c *Client) do(ctx context.Context, method, path string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, method, baseURL+path, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.token)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	return c.client.Do(req)
}

func (c *Client) decode(resp *http.Response, v any) error {
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("GitHub API %d: %s", resp.StatusCode, string(b))
	}
	return jsonDecode(resp.Body, v)
}

type progressReader struct {
	r          io.Reader
	total      int64
	downloaded int64
	fn         func(int64, int64)
}

func (p *progressReader) Read(b []byte) (int, error) {
	n, err := p.r.Read(b)
	p.downloaded += int64(n)
	if p.fn != nil {
		p.fn(p.downloaded, p.total)
	}
	return n, err
}
```

- [ ] **Step 3: Write internal/github/workflow.go**

```go
package github

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"strings"
	"time"
)

func jsonDecode(r io.Reader, v any) error {
	return json.NewDecoder(r).Decode(v)
}

func (c *Client) TriggerWorkflow(ctx context.Context, owner, repo, workflowFile string, inputs map[string]string) error {
	type payload struct {
		Ref    string            `json:"ref"`
		Inputs map[string]string `json:"inputs"`
	}
	b, _ := json.Marshal(payload{Ref: "main", Inputs: inputs})
	path := fmt.Sprintf("/repos/%s/%s/actions/workflows/%s/dispatches", owner, repo, workflowFile)
	resp, err := c.do(ctx, "POST", path, strings.NewReader(string(b)))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode == 404 {
		return fmt.Errorf("workflow %s not found — run: builder init", workflowFile)
	}
	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("trigger workflow: %d %s", resp.StatusCode, body)
	}
	return nil
}

func (c *Client) PollForWorkflowStart(ctx context.Context, owner, repo, workflowFile string, after time.Time, timeout time.Duration) (*WorkflowRun, error) {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		created := url.QueryEscape(">=" + after.UTC().Format(time.RFC3339))
		path := fmt.Sprintf("/repos/%s/%s/actions/workflows/%s/runs?event=workflow_dispatch&created=%s&per_page=5",
			owner, repo, workflowFile, created)
		resp, err := c.do(ctx, "GET", path, nil)
		if err != nil {
			return nil, err
		}
		var result listRunsResponse
		if err := c.decode(resp, &result); err != nil {
			return nil, err
		}
		for i, run := range result.WorkflowRuns {
			if run.CreatedAt.After(after) || run.CreatedAt.Equal(after) {
				return &result.WorkflowRuns[i], nil
			}
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(3 * time.Second):
		}
	}
	return nil, fmt.Errorf("workflow did not start within %s", timeout)
}

func (c *Client) GetWorkflowRun(ctx context.Context, owner, repo string, runID int64) (*WorkflowRun, error) {
	path := fmt.Sprintf("/repos/%s/%s/actions/runs/%d", owner, repo, runID)
	resp, err := c.do(ctx, "GET", path, nil)
	if err != nil {
		return nil, err
	}
	var run WorkflowRun
	return &run, c.decode(resp, &run)
}

func (c *Client) PollForArtifact(ctx context.Context, owner, repo string, runID int64, artifactName string, timeout time.Duration) (*Artifact, error) {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		path := fmt.Sprintf("/repos/%s/%s/actions/runs/%d/artifacts", owner, repo, runID)
		resp, err := c.do(ctx, "GET", path, nil)
		if err != nil {
			return nil, err
		}
		var result listArtifactsResponse
		if err := c.decode(resp, &result); err != nil {
			return nil, err
		}
		for i, a := range result.Artifacts {
			if a.Name == artifactName {
				return &result.Artifacts[i], nil
			}
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(10 * time.Second):
		}
	}
	return nil, fmt.Errorf("artifact %q not available after %s", artifactName, timeout)
}

func (c *Client) DownloadArtifactWithProgress(ctx context.Context, owner, repo string, artifactID int64, onProgress func(int64, int64)) ([]byte, error) {
	path := fmt.Sprintf("/repos/%s/%s/actions/artifacts/%d/zip", owner, repo, artifactID)
	resp, err := c.do(ctx, "GET", path, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("download artifact: %d %s", resp.StatusCode, b)
	}
	pr := &progressReader{r: resp.Body, total: resp.ContentLength, fn: onProgress}
	return io.ReadAll(pr)
}
```

- [ ] **Step 4: Verify compile**

```bash
go build ./internal/github/...
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add internal/github/
git commit -m "feat: GitHub API client (trigger, poll, download artifact)"
```

---

### Task 5: Build progress UI + coordinator

**Files:**
- Create: `internal/build/progress.go`
- Create: `internal/build/coordinator.go`

- [ ] **Step 1: Write internal/build/progress.go**

```go
package build

import (
	"fmt"
	"io"
	"time"
)

type Phase string

const (
	PhaseTriggering   Phase = "triggering"
	PhaseWaitingStart Phase = "waiting"
	PhaseBuilding     Phase = "building"
	PhaseDownloading  Phase = "downloading"
)

type Progress struct {
	w           io.Writer
	buildID     string
	workflowURL string
	start       time.Time
}

func NewProgress(w io.Writer) *Progress { return &Progress{w: w, start: time.Now()} }

func (p *Progress) Start(buildID string) {
	p.buildID = buildID
	fmt.Fprintf(p.w, "android-builder — build %s\n\n", buildID)
}

func (p *Progress) Update(_ Phase, msg string) { fmt.Fprintf(p.w, "  ⏳ %s\n", msg) }

func (p *Progress) Complete(_ Phase, msg string) { fmt.Fprintf(p.w, "  ✅ %s\n", msg) }

func (p *Progress) Error(_ Phase, err error) { fmt.Fprintf(p.w, "  ❌ %v\n", err) }

func (p *Progress) SetWorkflowURL(u string) {
	p.workflowURL = u
	fmt.Fprintf(p.w, "  🔗 %s\n", u)
}

func (p *Progress) UpdateDownloadProgress(downloaded, total int64) {
	if total > 0 {
		fmt.Fprintf(p.w, "\r  ⬇️  %.0f%%", float64(downloaded)/float64(total)*100)
	}
}

func (p *Progress) Finish() {
	fmt.Fprintf(p.w, "\n\nDone in %s\n", time.Since(p.start).Round(time.Second))
}
```

- [ ] **Step 2: Write internal/build/coordinator.go**

```go
package build

import (
	"archive/zip"
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/github"
	"github.com/google/uuid"
)

const (
	DefaultTimeout  = 30 * time.Minute
	WorkflowFile    = "android-build.yml"
	APKArtifactName = "apk"
)

type Coordinator struct {
	config   *config.Config
	github   *github.Client
	progress *Progress
}

func NewCoordinator(cfg *config.Config, gh *github.Client) *Coordinator {
	return &Coordinator{config: cfg, github: gh, progress: NewProgress(os.Stdout)}
}

type BuildOptions struct {
	OutputDir string
	Timeout   time.Duration
	Release   bool
}

type BuildResult struct {
	BuildID     string
	APKPath     string
	Duration    time.Duration
	WorkflowURL string
	APKSize     int64
}

func (c *Coordinator) Build(ctx context.Context, opts BuildOptions) (*BuildResult, error) {
	start := time.Now()
	if opts.Timeout == 0 {
		opts.Timeout = DefaultTimeout
	}
	ctx, cancel := context.WithTimeout(ctx, opts.Timeout)
	defer cancel()

	buildID := uuid.New().String()[:8]
	c.progress.Start(buildID)

	buildType := "debug"
	if opts.Release {
		buildType = "release"
	}

	c.progress.Update(PhaseTriggering, "Triggering GitHub Actions build...")
	triggerTime := time.Now()
	inputs := map[string]string{"build_id": buildID, "build_type": buildType}
	if c.config.Flutter.Version != "" {
		inputs["flutter_version"] = c.config.Flutter.Version
	}
	if err := c.github.TriggerWorkflow(ctx, c.config.GitHub.Owner, c.config.GitHub.Repo, WorkflowFile, inputs); err != nil {
		c.progress.Error(PhaseTriggering, err)
		return nil, fmt.Errorf("trigger: %w", err)
	}
	c.progress.Complete(PhaseTriggering, "Workflow triggered")

	c.progress.Update(PhaseWaitingStart, "Waiting for workflow to start...")
	run, err := c.github.PollForWorkflowStart(ctx, c.config.GitHub.Owner, c.config.GitHub.Repo, WorkflowFile, triggerTime, 2*time.Minute)
	if err != nil {
		c.progress.Error(PhaseWaitingStart, err)
		return nil, fmt.Errorf("start: %w", err)
	}
	c.progress.Complete(PhaseWaitingStart, fmt.Sprintf("Workflow started (run #%d)", run.ID))
	c.progress.SetWorkflowURL(run.HTMLURL)

	c.progress.Update(PhaseBuilding, "Building APK... (ubuntu-latest, ~3–5 min)")
	artifact, err := c.github.PollForArtifact(ctx, c.config.GitHub.Owner, c.config.GitHub.Repo, run.ID, APKArtifactName, opts.Timeout)
	if err != nil {
		c.progress.Error(PhaseBuilding, err)
		return nil, fmt.Errorf("build: %w", err)
	}
	c.progress.Complete(PhaseBuilding, "Build complete")

	c.progress.Update(PhaseDownloading, "Downloading APK...")
	apkPath, apkSize, err := c.downloadAPK(ctx, opts.OutputDir, artifact.ID, buildID)
	if err != nil {
		c.progress.Error(PhaseDownloading, err)
		return nil, fmt.Errorf("download: %w", err)
	}
	c.progress.Complete(PhaseDownloading, fmt.Sprintf("Downloaded (%.2f MB)", float64(apkSize)/(1024*1024)))
	c.progress.Finish()

	return &BuildResult{
		BuildID:     buildID,
		APKPath:     apkPath,
		Duration:    time.Since(start),
		WorkflowURL: run.HTMLURL,
		APKSize:     apkSize,
	}, nil
}

func (c *Coordinator) downloadAPK(ctx context.Context, outputDir string, artifactID int64, buildID string) (string, int64, error) {
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return "", 0, err
	}
	zipData, err := c.github.DownloadArtifactWithProgress(ctx, c.config.GitHub.Owner, c.config.GitHub.Repo, artifactID, func(d, t int64) {
		c.progress.UpdateDownloadProgress(d, t)
	})
	if err != nil {
		return "", 0, err
	}
	dest := filepath.Join(outputDir, fmt.Sprintf("%s-%s.apk", c.config.Project, buildID))
	size, err := extractAPKFromZip(zipData, dest)
	return dest, size, err
}

func extractAPKFromZip(zipData []byte, destPath string) (int64, error) {
	r, err := zip.NewReader(bytes.NewReader(zipData), int64(len(zipData)))
	if err != nil {
		return 0, err
	}
	for _, f := range r.File {
		if filepath.Ext(f.Name) == ".apk" {
			rc, err := f.Open()
			if err != nil {
				return 0, err
			}
			defer rc.Close()
			out, err := os.Create(destPath)
			if err != nil {
				return 0, err
			}
			defer out.Close()
			return io.Copy(out, rc)
		}
	}
	return 0, fmt.Errorf("no .apk found in artifact zip")
}
```

- [ ] **Step 3: Verify compile**

```bash
go build ./internal/build/...
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add internal/build/
git commit -m "feat: build coordinator + progress UI"
```

---

### Task 6: GHA workflow template

**Files:**
- Create: `internal/workflow/templates/android-build.yml`
- Create: `internal/workflow/templates.go`

- [ ] **Step 1: Write internal/workflow/templates/android-build.yml**

```yaml
name: Android Build

on:
  workflow_dispatch:
    inputs:
      build_id:
        description: 'Unique build identifier'
        required: true
        type: string
      build_type:
        description: 'Build type: debug or release'
        required: false
        type: string
        default: 'debug'
      flutter_version:
        description: 'Flutter version (empty = latest stable)'
        required: false
        type: string
        default: ''

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    defaults:
      run:
        working-directory: app

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ inputs.flutter_version || '' }}
          channel: stable
          cache: true

      - name: Restore Gradle cache
        uses: actions/cache@v4
        id: gradle-cache
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('android/build.gradle', 'android/app/build.gradle', 'android/settings.gradle.kts') }}
          restore-keys: |
            gradle-${{ runner.os }}-

      - name: Flutter pub get
        run: flutter pub get

      - name: Build APK
        env:
          BUILD_ID: ${{ inputs.build_id }}
          BUILD_TYPE: ${{ inputs.build_type }}
        run: |
          set -e
          if [ "$BUILD_TYPE" = "release" ]; then
            flutter build apk --release
            SRC="build/app/outputs/flutter-apk/app-release.apk"
          else
            flutter build apk --debug
            SRC="build/app/outputs/flutter-apk/app-debug.apk"
          fi
          mkdir -p build/dist
          cp "$SRC" "build/dist/${BUILD_ID}.apk"
          echo "APK: build/dist/${BUILD_ID}.apk ($(du -h "build/dist/${BUILD_ID}.apk" | cut -f1))"

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: apk
          path: app/build/dist/*.apk
          retention-days: 7
          if-no-files-found: error

      - name: Save Gradle cache
        uses: actions/cache/save@v4
        if: always()
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('android/build.gradle', 'android/app/build.gradle', 'android/settings.gradle.kts') }}

      - name: Build summary
        if: always()
        run: |
          echo "## Android Build Summary" >> $GITHUB_STEP_SUMMARY
          echo "- **Build ID:** ${{ inputs.build_id }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Status:** ${{ job.status }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Build Type:** ${{ inputs.build_type }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Gradle Cache:** ${{ steps.gradle-cache.outputs.cache-hit == 'true' && 'Hit' || 'Miss' }}" >> $GITHUB_STEP_SUMMARY
          if [ -f "build/dist/${{ inputs.build_id }}.apk" ]; then
            echo "- **APK Size:** $(du -h "build/dist/${{ inputs.build_id }}.apk" | cut -f1)" >> $GITHUB_STEP_SUMMARY
          fi
```

- [ ] **Step 2: Write internal/workflow/templates.go**

```go
package workflow

import _ "embed"

//go:embed templates/android-build.yml
var androidBuildWorkflow []byte

func GetWorkflowTemplate() ([]byte, error) {
	return androidBuildWorkflow, nil
}
```

- [ ] **Step 3: Verify embed compiles**

```bash
go build ./internal/workflow/...
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add internal/workflow/
git commit -m "feat: android-build.yml GHA workflow template (ubuntu-latest)"
```

---

### Task 7: File watcher + tests (TDD)

**Files:**
- Create: `internal/dev/watcher.go`
- Create: `internal/dev/watcher_test.go`

- [ ] **Step 1: Write failing tests**

`internal/dev/watcher_test.go`:
```go
package dev_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/dev"
)

func TestWatcherDetectsChange(t *testing.T) {
	dir := t.TempDir()
	libDir := filepath.Join(dir, "lib")
	os.MkdirAll(libDir, 0755)
	dartFile := filepath.Join(libDir, "main.dart")
	os.WriteFile(dartFile, []byte("// initial"), 0644)

	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	fired := make(chan struct{}, 1)
	cfg := &config.WatchConfig{Dirs: []string{"lib"}, Patterns: []string{".dart"}, Debounce: 50}
	w := dev.NewWatcher(cfg, func() { fired <- struct{}{} })

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	go w.Run(ctx)

	time.Sleep(300 * time.Millisecond) // let initial scan populate seen map

	os.WriteFile(dartFile, []byte("// changed"), 0644)

	select {
	case <-fired:
	case <-ctx.Done():
		t.Fatal("watcher did not fire")
	}
}

func TestWatcherIgnoresPattern(t *testing.T) {
	dir := t.TempDir()
	libDir := filepath.Join(dir, "lib")
	os.MkdirAll(libDir, 0755)
	genFile := filepath.Join(libDir, "foo.g.dart")
	os.WriteFile(genFile, []byte("// initial"), 0644)

	orig, _ := os.Getwd()
	defer os.Chdir(orig)
	os.Chdir(dir)

	fired := make(chan struct{}, 1)
	cfg := &config.WatchConfig{Dirs: []string{"lib"}, Patterns: []string{".dart"}, Ignore: []string{".g.dart"}, Debounce: 50}
	w := dev.NewWatcher(cfg, func() { fired <- struct{}{} })

	ctx, cancel := context.WithTimeout(context.Background(), 800*time.Millisecond)
	defer cancel()
	go w.Run(ctx)

	time.Sleep(300 * time.Millisecond)
	os.WriteFile(genFile, []byte("// changed"), 0644)

	select {
	case <-fired:
		t.Fatal("watcher fired for ignored file")
	case <-ctx.Done():
		// expected
	}
}
```

- [ ] **Step 2: Run tests — expect compile failure**

```bash
go test ./internal/dev/... 2>&1 | head -5
```
Expected: `cannot find package "github.com/Maortz/android-builder/internal/dev"`

- [ ] **Step 3: Write internal/dev/watcher.go**

```go
package dev

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/Maortz/android-builder/internal/config"
)

type Watcher struct {
	cfg      *config.WatchConfig
	onChange func()
	seen     map[string]time.Time
}

func NewWatcher(cfg *config.WatchConfig, onChange func()) *Watcher {
	if cfg == nil {
		cfg = &config.WatchConfig{Dirs: []string{"lib"}, Patterns: []string{".dart"}, Debounce: 100}
	}
	return &Watcher{cfg: cfg, onChange: onChange, seen: make(map[string]time.Time)}
}

func (w *Watcher) Run(ctx context.Context) {
	debounce := time.Duration(w.cfg.Debounce) * time.Millisecond
	if debounce == 0 {
		debounce = 100 * time.Millisecond
	}

	var pending bool
	var timer *time.Timer
	tick := time.NewTicker(200 * time.Millisecond)
	defer tick.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-tick.C:
			if w.scanChanges() && !pending {
				pending = true
				if timer != nil {
					timer.Stop()
				}
				timer = time.AfterFunc(debounce, func() {
					pending = false
					w.onChange()
				})
			}
		}
	}
}

func (w *Watcher) scanChanges() bool {
	changed := false
	for _, dir := range w.cfg.Dirs {
		_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil || info.IsDir() {
				return nil
			}
			if !w.matches(path) || w.ignored(path) {
				return nil
			}
			prev, seen := w.seen[path]
			if !seen || info.ModTime().After(prev) {
				w.seen[path] = info.ModTime()
				if seen {
					changed = true
				}
			}
			return nil
		})
	}
	return changed
}

func (w *Watcher) matches(path string) bool {
	if len(w.cfg.Patterns) == 0 {
		return true
	}
	for _, p := range w.cfg.Patterns {
		if strings.HasSuffix(path, p) {
			return true
		}
	}
	return false
}

func (w *Watcher) ignored(path string) bool {
	for _, ig := range w.cfg.Ignore {
		if strings.HasSuffix(path, ig) {
			return true
		}
	}
	return false
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
go test ./internal/dev/... -v -run TestWatcher
```
Expected: both watcher tests PASS.

- [ ] **Step 5: Commit**

```bash
git add internal/dev/watcher.go internal/dev/watcher_test.go
git commit -m "feat: file watcher with debounce, pattern + ignore support"
```

---

### Task 8: Dev session (adb install, package detect, flutter attach)

**Files:**
- Create: `internal/dev/session.go`
- Create: `internal/dev/flutter.go`

- [ ] **Step 1: Write internal/dev/session.go**

```go
package dev

import (
	"context"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/manifoldco/promptui"
)

// Session manages adb install → app launch → flutter attach.
type Session struct {
	deviceID    string
	apkPath     string
	packageName string
	skipInstall bool
	handler     *FlutterHandler
}

func NewSession(deviceID, apkPath string, handler *FlutterHandler) *Session {
	return &Session{deviceID: deviceID, apkPath: apkPath, handler: handler}
}

func (s *Session) SetSkipInstall(skip bool, packageName string) {
	s.skipInstall = skip
	s.packageName = packageName
}

// FindAPK returns the newest .apk in distDir, prompting if multiple.
func FindAPK(distDir string) (string, error) {
	matches, err := filepath.Glob(filepath.Join(distDir, "*.apk"))
	if err != nil || len(matches) == 0 {
		return "", fmt.Errorf("no APK in %s — run 'builder android build' first", distDir)
	}
	if len(matches) == 1 {
		return matches[0], nil
	}
	prompt := promptui.Select{Label: "Select APK", Items: matches}
	_, selected, err := prompt.Run()
	return selected, err
}

func (s *Session) Start(ctx context.Context) error {
	deviceID, err := s.selectDevice()
	if err != nil {
		return err
	}
	s.deviceID = deviceID

	if !s.skipInstall {
		fmt.Printf("Installing %s...\n", s.apkPath)
		if err := adbRun(ctx, deviceID, "install", "-r", s.apkPath); err != nil {
			return fmt.Errorf("adb install: %w", err)
		}
		fmt.Println("Installed.")

		if s.packageName == "" {
			pkg, err := detectPackageName(s.apkPath)
			if err != nil {
				return fmt.Errorf("%w\nUse --package com.your.app or set android.packageName in builder.json", err)
			}
			s.packageName = pkg
		}

		fmt.Printf("Launching %s...\n", s.packageName)
		if err := adbRun(ctx, deviceID, "shell", "monkey", "-p", s.packageName, "-c", "android.intent.category.LAUNCHER", "1"); err != nil {
			return fmt.Errorf("launch app: %w", err)
		}
	}

	return s.handler.Attach(ctx, deviceID, s.packageName)
}

func (s *Session) selectDevice() (string, error) {
	if s.deviceID != "" {
		return s.deviceID, nil
	}
	devices, err := listDevices()
	if err != nil {
		return "", err
	}
	if len(devices) == 0 {
		return "", fmt.Errorf("no Android devices found\nEnable USB debugging and reconnect, then check: adb devices")
	}
	if len(devices) == 1 {
		fmt.Printf("Device: %s\n", devices[0])
		return devices[0], nil
	}
	prompt := promptui.Select{Label: "Select device", Items: devices}
	_, selected, err := prompt.Run()
	return selected, err
}

func listDevices() ([]string, error) {
	out, err := exec.Command("adb", "devices").Output()
	if err != nil {
		return nil, fmt.Errorf("adb not found: %w\nInstall Platform-Tools: https://developer.android.com/tools/releases/platform-tools", err)
	}
	var devices []string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "List of") || strings.HasPrefix(line, "*") {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) >= 2 && parts[1] == "device" {
			devices = append(devices, parts[0])
		}
	}
	return devices, nil
}

func adbRun(ctx context.Context, deviceID string, args ...string) error {
	fullArgs := append([]string{"-s", deviceID}, args...)
	out, err := exec.CommandContext(ctx, "adb", fullArgs...).CombinedOutput()
	if err != nil {
		return fmt.Errorf("%w\n%s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

func detectPackageName(apkPath string) (string, error) {
	tools := []string{"aapt", "aapt2"}
	var out []byte
	var err error
	for _, tool := range tools {
		out, err = exec.Command(tool, "dump", "badging", apkPath).Output()
		if err == nil {
			break
		}
	}
	if err != nil {
		return "", fmt.Errorf("aapt/aapt2 not found — could not detect package name")
	}
	for _, line := range strings.Split(string(out), "\n") {
		if !strings.HasPrefix(line, "package: name=") {
			continue
		}
		for _, field := range strings.Fields(line) {
			if strings.HasPrefix(field, "name=") {
				return strings.Trim(strings.TrimPrefix(field, "name="), `'"`), nil
			}
		}
	}
	return "", fmt.Errorf("could not parse package name from aapt output")
}
```

- [ ] **Step 2: Write internal/dev/flutter.go**

```go
package dev

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"os/exec"
	"strings"
	"time"

	"github.com/Maortz/android-builder/internal/config"
)

type FlutterHandler struct {
	noAttach bool
	noWatch  bool
	watchCfg *config.WatchConfig
	cmd      *exec.Cmd
	stdin    io.WriteCloser
}

func NewFlutterHandler(noAttach, noWatch bool, watchCfg *config.WatchConfig) *FlutterHandler {
	return &FlutterHandler{noAttach: noAttach, noWatch: noWatch, watchCfg: watchCfg}
}

func (h *FlutterHandler) Attach(ctx context.Context, deviceID, _ string) error {
	args := []string{"attach", "--device-id", deviceID}

	if h.noAttach {
		fmt.Printf("\nRun manually:\n  flutter %s\n", strings.Join(args, " "))
		return nil
	}

	fmt.Println("\nStarting flutter attach...")
	h.cmd = exec.CommandContext(ctx, "flutter", args...)

	stdin, err := h.cmd.StdinPipe()
	if err != nil {
		return fmt.Errorf("stdin pipe: %w", err)
	}
	h.stdin = stdin

	stdout, err := h.cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("stdout pipe: %w", err)
	}
	h.cmd.Stderr = h.cmd.Stdout

	if err := h.cmd.Start(); err != nil {
		return fmt.Errorf("flutter attach: %w", err)
	}

	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			fmt.Println(scanner.Text())
		}
	}()

	if !h.noWatch {
		w := NewWatcher(h.watchCfg, func() {
			if h.stdin != nil {
				_, _ = fmt.Fprintln(h.stdin, "r")
				fmt.Printf("[%s] Hot reload\n", time.Now().Format("15:04:05"))
			}
		})
		go w.Run(ctx)
	}

	return h.cmd.Wait()
}

func (h *FlutterHandler) Stop() {
	if h.stdin != nil {
		_ = h.stdin.Close()
	}
	if h.cmd != nil && h.cmd.Process != nil {
		_ = h.cmd.Process.Kill()
	}
}
```

- [ ] **Step 3: Verify compile**

```bash
go build ./internal/dev/...
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add internal/dev/session.go internal/dev/flutter.go
git commit -m "feat: dev session — adb install, package detect, flutter attach"
```

---

### Task 9: CLI commands + root

**Files:**
- Create: `cmd/builder/root.go`
- Create: `cmd/builder/auth.go`
- Create: `cmd/builder/android.go`
- Create: `cmd/builder/init.go`
- Create: `cmd/builder/flutter.go`

- [ ] **Step 1: Write cmd/builder/root.go**

```go
package main

import (
	"fmt"

	"github.com/Maortz/android-builder/internal/auth"
	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/github"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:          "builder",
	Short:        "Build Android apps remotely using GitHub Actions",
	SilenceUsage: true,
}

func init() {
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(androidCmd)
	rootCmd.AddCommand(authCmd)
	rootCmd.AddCommand(devCmd)
}

func getGitHubClient() (*github.Client, error) {
	token, err := auth.GetToken()
	if err != nil {
		return nil, fmt.Errorf("not authenticated. Run: builder auth github")
	}
	return github.NewClient(token), nil
}

func loadConfig() (*config.Config, error) {
	mgr := config.NewManager()
	cfg, err := mgr.Load()
	if err != nil {
		if err == config.ErrConfigNotFound {
			return nil, fmt.Errorf("builder.json not found. Run: builder init")
		}
		return nil, err
	}
	return cfg, nil
}
```

- [ ] **Step 2: Write cmd/builder/auth.go**

```go
package main

import (
	"fmt"
	"syscall"

	"github.com/Maortz/android-builder/internal/auth"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var authCmd = &cobra.Command{Use: "auth", Short: "Authentication commands"}

var authGithubCmd = &cobra.Command{
	Use:   "github",
	Short: "Save GitHub personal access token",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Print("GitHub token (needs repo + actions:read scope): ")
		b, err := term.ReadPassword(int(syscall.Stdin))
		if err != nil {
			return err
		}
		fmt.Println()
		if len(b) == 0 {
			return fmt.Errorf("token cannot be empty")
		}
		if err := auth.SetToken(string(b)); err != nil {
			return fmt.Errorf("save token: %w", err)
		}
		fmt.Println("Token saved.")
		return nil
	},
}

func init() { authCmd.AddCommand(authGithubCmd) }
```

- [ ] **Step 3: Write cmd/builder/android.go**

```go
package main

import (
	"context"
	"fmt"
	"time"

	"github.com/Maortz/android-builder/internal/build"
	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/github"
	"github.com/spf13/cobra"
)

var androidCmd = &cobra.Command{Use: "android", Short: "Android build commands"}

var androidBuildCmd = &cobra.Command{
	Use:   "build",
	Short: "Trigger a remote Android build on GitHub Actions",
	RunE:  runAndroidBuild,
}

func init() {
	androidBuildCmd.Flags().StringP("output", "o", "dist", "Output directory for APK")
	androidBuildCmd.Flags().Duration("timeout", 30*time.Minute, "Build timeout")
	androidBuildCmd.Flags().Bool("release", false, "Build release APK instead of debug")
	androidCmd.AddCommand(androidBuildCmd)
}

func runAndroidBuild(cmd *cobra.Command, args []string) error {
	cfg, err := loadConfig()
	if err != nil {
		return err
	}
	if err := cfg.Validate(); err != nil {
		return err
	}
	output, _ := cmd.Flags().GetString("output")
	timeout, _ := cmd.Flags().GetDuration("timeout")
	release, _ := cmd.Flags().GetBool("release")
	return triggerBuild(cmd.Context(), cfg, output, timeout, release)
}

func triggerBuild(ctx context.Context, cfg *config.Config, outputDir string, timeout time.Duration, release bool) error {
	gh, err := getGitHubClient()
	if err != nil {
		return err
	}
	coord := build.NewCoordinator(cfg, gh)
	result, err := coord.Build(ctx, build.BuildOptions{
		OutputDir: outputDir,
		Timeout:   timeout,
		Release:   release,
	})
	if err != nil {
		return err
	}
	fmt.Printf("APK: %s\n", result.APKPath)
	fmt.Printf("Workflow: %s\n", result.WorkflowURL)
	return nil
}

// keep unused import happy until loadConfig references github in root.go
var _ *github.Client
```

- [ ] **Step 4: Write cmd/builder/init.go**

```go
package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/workflow"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize Android builds for this repository",
	RunE:  runInit,
}

func init() {
	initCmd.Flags().StringP("project", "p", "", "Project name (default: current directory name)")
	initCmd.Flags().StringP("remote", "r", "origin", "Git remote name")
}

func detectGitHubRepo(remote string) (owner, repo string, err error) {
	out, err := exec.Command("git", "remote", "get-url", remote).Output()
	if err != nil {
		return "", "", fmt.Errorf("no '%s' remote", remote)
	}
	u := strings.TrimSuffix(strings.TrimSpace(string(out)), ".git")
	if path, ok := strings.CutPrefix(u, "https://github.com/"); ok {
		parts := strings.SplitN(path, "/", 2)
		if len(parts) == 2 {
			return parts[0], parts[1], nil
		}
	}
	if strings.HasPrefix(u, "git@") {
		if i := strings.Index(u, ":"); i > 0 {
			parts := strings.SplitN(u[i+1:], "/", 2)
			if len(parts) == 2 {
				return parts[0], parts[1], nil
			}
		}
	}
	return "", "", fmt.Errorf("could not parse GitHub URL: %s", u)
}

func getLocalFlutterVersion() string {
	out, err := exec.Command("flutter", "--version", "--machine").Output()
	if err != nil {
		return ""
	}
	s := string(out)
	key := `"frameworkVersion":"`
	i := strings.Index(s, key)
	if i < 0 {
		return ""
	}
	s = s[i+len(key):]
	if j := strings.Index(s, `"`); j >= 0 {
		return s[:j]
	}
	return ""
}

func runInit(cmd *cobra.Command, args []string) error {
	remote, _ := cmd.Flags().GetString("remote")
	owner, repoName, err := detectGitHubRepo(remote)
	if err != nil {
		return err
	}
	fmt.Printf("Repository: %s/%s\n\n", owner, repoName)

	projectName, _ := cmd.Flags().GetString("project")
	if projectName == "" {
		cwd, _ := os.Getwd()
		p := promptui.Prompt{Label: "Project name", Default: filepath.Base(cwd)}
		projectName, err = p.Run()
		if err != nil {
			return err
		}
	}

	localVer := getLocalFlutterVersion()
	fp := promptui.Prompt{Label: "Flutter version (empty = latest stable)", Default: localVer}
	flutterVersion, _ := fp.Run()

	// Write workflow file
	if err := os.MkdirAll(".github/workflows", 0755); err != nil {
		return err
	}
	tmpl, err := workflow.GetWorkflowTemplate()
	if err != nil {
		return err
	}
	workflowPath := ".github/workflows/android-build.yml"
	if err := os.WriteFile(workflowPath, tmpl, 0644); err != nil {
		return err
	}
	fmt.Printf("Created: %s\n", workflowPath)

	// Merge into existing builder.json if present (preserves ios section)
	mgr := config.NewManager()
	cfg, err := mgr.Load()
	if err != nil {
		cfg = &config.Config{}
	}
	cfg.Project = projectName
	cfg.Platform = "android"
	cfg.GitHub = config.GitHubConfig{Owner: owner, Repo: repoName}
	cfg.Android = config.AndroidConfig{BuildType: "debug"}
	cfg.Flutter.Version = flutterVersion
	if err := mgr.Save(cfg); err != nil {
		return err
	}
	fmt.Println("Updated: builder.json")

	// Offer commit+push
	cp := promptui.Prompt{Label: "Commit and push", IsConfirm: true}
	if _, err := cp.Run(); err == nil {
		exec.Command("git", "add", workflowPath, "builder.json").Run()
		exec.Command("git", "commit", "-m", "Add Android build workflow").Run()
		exec.Command("git", "push").Run()
		fmt.Println("Pushed.")
	}

	// Offer immediate build
	bp := promptui.Prompt{Label: "Run build now", IsConfirm: true}
	if _, err := bp.Run(); err == nil {
		return triggerBuild(context.Background(), cfg, "dist", 30*time.Minute, false)
	}

	fmt.Println("\nTo build: builder android build")
	return nil
}
```

- [ ] **Step 5: Write cmd/builder/flutter.go**

```go
package main

import (
	"fmt"
	"os"

	"github.com/Maortz/android-builder/internal/config"
	"github.com/Maortz/android-builder/internal/dev"
	"github.com/spf13/cobra"
)

var devCmd = &cobra.Command{Use: "dev", Short: "Development commands"}

var devFlutterCmd = &cobra.Command{
	Use:   "flutter",
	Short: "Install APK and start Flutter hot-reload session",
	RunE:  runDevFlutter,
}

func init() {
	devFlutterCmd.Flags().StringP("device", "d", "", "ADB device ID (default: first available)")
	devFlutterCmd.Flags().String("apk", "", "Path to APK (default: auto-detect from dist/)")
	devFlutterCmd.Flags().String("package", "", "App package name (e.g. com.example.app)")
	devFlutterCmd.Flags().Bool("skip-install", false, "Skip APK install (requires --package)")
	devFlutterCmd.Flags().Bool("no-attach", false, "Print flutter attach command instead of running")
	devFlutterCmd.Flags().Bool("no-watch", false, "Disable file-change hot reload")
	devCmd.AddCommand(devFlutterCmd)
}

func runDevFlutter(cmd *cobra.Command, args []string) error {
	deviceID, _ := cmd.Flags().GetString("device")
	apkPath, _ := cmd.Flags().GetString("apk")
	packageName, _ := cmd.Flags().GetString("package")
	skipInstall, _ := cmd.Flags().GetBool("skip-install")
	noAttach, _ := cmd.Flags().GetBool("no-attach")
	noWatch, _ := cmd.Flags().GetBool("no-watch")

	watchCfg := &config.WatchConfig{
		Dirs:     []string{"lib"},
		Patterns: []string{".dart"},
		Ignore:   []string{".g.dart", ".freezed.dart"},
		Debounce: 100,
	}

	if cfg, err := loadConfig(); err == nil {
		if len(cfg.Flutter.Watch.Dirs) > 0 {
			watchCfg = &cfg.Flutter.Watch
		}
		if packageName == "" {
			packageName = cfg.Android.PackageName
		}
	}

	if skipInstall && packageName == "" {
		return fmt.Errorf("--package is required with --skip-install")
	}

	if !skipInstall {
		if apkPath == "" {
			var err error
			apkPath, err = dev.FindAPK("dist")
			if err != nil {
				return err
			}
		}
		if _, err := os.Stat(apkPath); os.IsNotExist(err) {
			return fmt.Errorf("APK not found: %s", apkPath)
		}
		fmt.Printf("APK: %s\n", apkPath)
	}

	handler := dev.NewFlutterHandler(noAttach, noWatch, watchCfg)
	session := dev.NewSession(deviceID, apkPath, handler)
	session.SetSkipInstall(skipInstall, packageName)
	return session.Start(cmd.Context())
}
```

- [ ] **Step 6: Build binary**

```bash
go build -o builder ./cmd/builder
```
Expected: produces `./builder` binary, no errors.

- [ ] **Step 7: Smoke-test CLI**

```bash
./builder --help
./builder android --help
./builder dev flutter --help
./builder auth --help
./builder init --help
```
Expected: help text for each command, no panics.

- [ ] **Step 8: Run all tests**

```bash
go test ./...
```
Expected: all tests PASS.

- [ ] **Step 9: Remove unused import in android.go**

Remove the `var _ *github.Client` line added in Step 3. The `github` import in `root.go` covers the package — `android.go` only needs `build` and `config`.

Edit `cmd/builder/android.go`: remove `"github.com/Maortz/android-builder/internal/github"` import and `var _ *github.Client` line.

- [ ] **Step 10: Commit**

```bash
git add cmd/builder/
git commit -m "feat: CLI commands — init, auth, android build, dev flutter"
```

---

### Task 10: install.sh + README

**Files:**
- Create: `install.sh`
- Create: `README.md`

- [ ] **Step 1: Write install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="Maortz/android-builder"
BINARY="builder"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
[ -z "$VERSION" ] && { echo "Could not get latest version"; exit 1; }

URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY}_${OS}_${ARCH}"
echo "Installing android-builder ${VERSION} (${OS}/${ARCH})..."
curl -fsSL "$URL" -o "/tmp/${BINARY}"
chmod +x "/tmp/${BINARY}"

if [ -w "$INSTALL_DIR" ]; then
    mv "/tmp/${BINARY}" "${INSTALL_DIR}/${BINARY}"
else
    sudo mv "/tmp/${BINARY}" "${INSTALL_DIR}/${BINARY}"
fi

echo "Installed: ${INSTALL_DIR}/${BINARY}"
echo ""
echo "Next steps:"
echo "  builder auth github       # save GitHub token"
echo "  builder init              # add android-build.yml + update builder.json"
echo "  builder android build     # trigger GHA build, download APK"
echo "  builder dev flutter       # install APK + hot-reload session"
```

- [ ] **Step 2: Write README.md**

````markdown
# android-builder

Build Android APKs remotely on GitHub Actions, download them, and start a Flutter hot-reload session on a connected device — from any OS.

Mirror of [MobAI-App/ios-builder](https://github.com/MobAI-App/ios-builder) for Android.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Maortz/android-builder/main/install.sh | bash
```

## Prerequisites

- GitHub account with a repo that contains a Flutter Android project
- `adb` on PATH ([Platform-Tools](https://developer.android.com/tools/releases/platform-tools))
- `flutter` on PATH
- Android device with USB debugging enabled

## Quick start

```bash
# 1. Authenticate
builder auth github

# 2. In your Flutter repo — adds android-build.yml + updates builder.json
builder init

# 3. Trigger build on GitHub Actions, download APK to dist/
builder android build

# 4. Install APK + start hot-reload session
builder dev flutter
```

## Commands

| Command | Description |
|---------|-------------|
| `builder auth github` | Save GitHub token |
| `builder init` | Write `android-build.yml` + `builder.json` |
| `builder android build` | Trigger GHA build → download APK to `dist/` |
| `builder android build --release` | Release APK |
| `builder dev flutter` | adb install → flutter attach + hot-reload |
| `builder dev flutter --no-watch` | Attach without file watcher |
| `builder dev flutter --skip-install --package com.x.y` | Skip install |

## builder.json

```json
{
  "project": "my-app",
  "platform": "android",
  "github": { "owner": "you", "repo": "my-app" },
  "android": {
    "buildType": "debug",
    "packageName": ""
  },
  "flutter": {
    "version": "3.24.0"
  }
}
```
````

- [ ] **Step 3: Commit**

```bash
chmod +x install.sh
git add install.sh README.md
git commit -m "docs: install.sh + README"
```

---

### Task 11: Wire android-build.yml into allergy-detector

This task runs in the **allergy-detector** repo, not android-builder.

**Files:**
- Modify: `/workspace/builder.json`
- Create: `/workspace/.github/workflows/android-build.yml`

- [ ] **Step 1: Update builder.json in allergy-detector**

Edit `/workspace/builder.json`:
```json
{
  "project": "allergy-detector",
  "platform": "android",
  "github": {
    "owner": "Maortz",
    "repo": "allergy-detector"
  },
  "android": {
    "buildType": "debug",
    "flavor": "",
    "packageName": ""
  },
  "flutter": {
    "watch": {}
  }
}
```

- [ ] **Step 2: Copy android-build.yml into allergy-detector**

Copy the template from `android-builder/internal/workflow/templates/android-build.yml` to `/workspace/.github/workflows/android-build.yml`.

- [ ] **Step 3: Verify workflow file**

```bash
cat /workspace/.github/workflows/android-build.yml | grep "runs-on"
```
Expected: `runs-on: ubuntu-latest`

- [ ] **Step 4: Commit**

```bash
cd /workspace
git add .github/workflows/android-build.yml builder.json
git commit -m "feat: add Android build workflow + update builder.json"
git push
```

- [ ] **Step 5: Manual smoke-test (from allergy-detector root)**

Install the built binary first:
```bash
cd /path/to/android-builder
make install
```

Then in allergy-detector:
```bash
builder android build
```
Expected: progress output → triggers GHA → polls artifact → downloads APK to `dist/`.

Monitor GHA at: `https://github.com/Maortz/allergy-detector/actions/workflows/android-build.yml`

---

## Self-Review

**Spec coverage check:**
- ✅ New Go repo `Maortz/android-builder` (Task 1)
- ✅ `builder.json` android section (Task 2, Task 11)
- ✅ GHA `android-build.yml` on `ubuntu-latest` (Task 6)
- ✅ `builder android build` → trigger → poll → download APK (Tasks 4–5, 7–9)
- ✅ `builder dev flutter` → adb install → detect package → launch → flutter attach (Tasks 8–9)
- ✅ File watcher → hot-reload on .dart change (Tasks 7, 9)
- ✅ `--no-attach`, `--no-watch`, `--skip-install`, `--device`, `--apk`, `--package` flags (Task 9)
- ✅ Error messages for missing adb, no devices, package detection failure (Task 8)
- ✅ `builder init` merges android section into existing builder.json (Task 9)
- ✅ install.sh for binary distribution (Task 10)

**Type consistency:**
- `WatchConfig` defined in `internal/config/types.go`, used in `internal/dev/watcher.go` and `internal/dev/flutter.go` ✅
- `FlutterHandler` created in `internal/dev/flutter.go`, used in `cmd/builder/flutter.go` ✅
- `Session.Start` / `Session.SetSkipInstall` / `FindAPK` all in `internal/dev/session.go` ✅
- `Coordinator.Build` / `BuildOptions` / `BuildResult` all in `internal/build/coordinator.go` ✅
- `WorkflowFile = "android-build.yml"` and `APKArtifactName = "apk"` in coordinator ✅
- `triggerBuild` helper defined in `cmd/builder/android.go`, called from `cmd/builder/init.go` ✅

**No placeholders:** all steps have actual code.
