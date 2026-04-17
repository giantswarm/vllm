# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-17

### Changed

- Revert base image from `nvidia/cuda:13.2.0-devel-ubuntu24.04` to `nvcr.io/nvidia/pytorch:26.03-py3` to fix TRITON_MLA kernel crash caused by Triton version mismatch.
- Remove manual PyTorch/Triton nightly installation (pre-installed in NGC container).
- Remove redundant apt-get dependencies (included in NGC container).
- Uninstall flash-attn from NGC base to avoid conflict with FlashInfer.
- Update Renovate config to track `nvcr.io/nvidia/pytorch` instead of `nvidia/cuda`.

## [0.1.0] - 2026-04-14

### Added

- Initial repository setup: Dockerfile for ARM64 vLLM serving image (DGX Spark / Blackwell GPUs).
- CI pipeline via architect-orb to build and push to gsoci.
- Prebuilt vLLM and FlashInfer wheels from eugr/spark-vllm-docker releases.
- Mistral Small 4 support (mistral-common >= 1.10.0, transformers from git).
