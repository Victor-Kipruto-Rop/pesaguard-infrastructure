.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help fmt validate lint clean plan apply destroy up down logs health backup restore dr-test diagnose test security

## help: Show this help message
help:
	@echo "PesaGuard Infrastructure — available targets"
	@echo ""
	@echo "  Implemented (Phase 1):"
	@echo "    make fmt        - Format Terraform files (terraform fmt -recursive)"
	@echo "    make validate   - Validate Terraform files that exist"
	@echo "    make lint       - Lint YAML and shell files"
	@echo "    make clean      - Remove local Terraform/dev artifacts"
	@echo ""
	@echo "  Not yet implemented (documented, not faked):"
	@echo "    make plan       - Terraform plan            (Phase 2)"
	@echo "    make apply      - Terraform apply           (Phase 2)"
	@echo "    make destroy    - Terraform destroy          (Phase 2, guarded)"
	@echo "    make up/down    - Local dev stack            (Phase 7)"
	@echo "    make logs       - Tail local dev stack logs  (Phase 7)"
	@echo "    make health     - Infrastructure health check (Phase 8)"
	@echo "    make backup     - Trigger a backup            (Phase 10)"
	@echo "    make restore    - Restore from backup         (Phase 10)"
	@echo "    make dr-test    - Safe DR validation, no destructive actions (Phase 10)"
	@echo "    make diagnose   - Run diagnostics              (Phase 8/10)"
	@echo "    make test       - Run infrastructure test suite (Phase 9)"
	@echo "    make security   - Run security scanners        (Phase 9)"

## fmt: Format all Terraform files (no-op until Terraform exists)
fmt:
	@if command -v terraform >/dev/null 2>&1 && [ -n "$$(find . -name '*.tf' 2>/dev/null)" ]; then \
		terraform fmt -recursive; \
	else \
		echo "No Terraform files yet (Phase 2) — nothing to format."; \
	fi

## validate: Validate Terraform configuration where it exists
validate:
	@if [ -n "$$(find . -name '*.tf' 2>/dev/null)" ]; then \
		for dir in $$(find . -name '*.tf' -exec dirname {} \; | sort -u); do \
			echo "Validating $$dir"; \
			(cd "$$dir" && terraform init -backend=false -input=false >/dev/null && terraform validate); \
		done; \
	else \
		echo "No Terraform files yet (Phase 2) — nothing to validate."; \
	fi

## lint: Lint YAML and shell scripts that exist in the repo
lint:
	@echo "Linting YAML files..."
	@if command -v yamllint >/dev/null 2>&1; then \
		find . -name '*.yml' -o -name '*.yaml' | grep -v '.terraform' | xargs -r yamllint; \
	else \
		echo "yamllint not installed — skipping (install with: pip install yamllint)"; \
	fi
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name '*.sh' | grep -v '.terraform' | xargs -r shellcheck || true; \
	else \
		echo "shellcheck not installed — skipping"; \
	fi
	@if [ -z "$$(find . -name '*.sh' 2>/dev/null)" ]; then \
		echo "No shell scripts yet (Phase 7+)."; \
	fi

## clean: Remove local Terraform and dev artifacts
clean:
	find . -type d -name '.terraform' -prune -exec rm -rf {} \;
	find . -type f -name '*.tfstate*' -delete
	find . -type f -name 'crash.log' -delete
	@echo "Cleaned local Terraform artifacts."
