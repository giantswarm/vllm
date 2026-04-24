##@ Helm

# `version` and `appVersion` in helm/vllm/Chart.yaml are templated as
# `[[ .Version ]]` so the architect orb substitutes them with the git tag at
# chart-build time. Local helm CLI invocations choke on the placeholder, so
# we copy the chart into a build dir and substitute a stub version before
# linting/templating.
HELM_CHART_DIR := helm/vllm
HELM_BUILD_DIR := build/vllm
HELM_STUB_VERSION ?= 0.0.0

.PHONY: helm-prepare
helm-prepare: ## Stage chart with stub version for local helm CLI use
	@rm -rf $(HELM_BUILD_DIR)
	@mkdir -p $(HELM_BUILD_DIR)
	@cp -r $(HELM_CHART_DIR)/. $(HELM_BUILD_DIR)/
	@sed -i 's/\[\[ .Version \]\]/$(HELM_STUB_VERSION)/g' $(HELM_BUILD_DIR)/Chart.yaml

.PHONY: helm-lint
helm-lint: helm-prepare ## Run Helm linter against the vllm chart
	@echo "Running Helm linter..."
	@helm lint $(HELM_BUILD_DIR)

.PHONY: helm-template
helm-template: helm-prepare ## Render the vllm chart with default values for sanity checks
	@helm template release $(HELM_BUILD_DIR)

.PHONY: check
check: helm-lint ## Run all chart-side linters
