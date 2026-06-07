.PHONY: up up-cron down build logs pipeline-pause pipeline-resume pipeline-status pipeline-log

# Start container (no cron)
up:
	docker compose up -d

# Start container with autonomous pipeline cron enabled (PowerShell)
up-cron:
	$env:ENABLE_CRON="1"; docker compose up -d

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

# --- Pipeline control (run inside container or via docker exec) ---
pipeline-pause:
	docker compose exec claude touch /tmp/cron-paused
	@echo "Pipeline paused."

pipeline-resume:
	docker compose exec claude rm -f /tmp/cron-paused
	@echo "Pipeline resumed."

pipeline-status:
	@docker compose exec claude sh -c '[ -f /tmp/cron-paused ] && echo "PAUSED" || echo "RUNNING"'

pipeline-log:
	docker compose exec claude tail -f /tmp/agent-pipeline.log
