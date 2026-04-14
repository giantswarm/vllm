# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-14

### Added

- Initial repository setup: Dockerfile for ARM64 vLLM serving image (DGX Spark / Blackwell GPUs).
- CI pipeline via architect-orb to build and push to gsoci.
- Prebuilt vLLM and FlashInfer wheels from eugr/spark-vllm-docker releases.
- Mistral Small 4 support (mistral-common >= 1.10.0, transformers from git).
