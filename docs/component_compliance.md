# nf-core Component Compliance Notes

This document tracks local components added while extending `nf-core/atacseq`.
It is intended as a development checklist before moving reusable modules or
subworkflows to `nf-core/modules`.

## Upstream Component Requirements

Reusable components should follow the nf-core component specifications before
submission to `nf-core/modules`:

- Create or port the component structure with `nf-core modules create` or
  `nf-core subworkflows create`.
- Keep modules focused on one tool or one clear command.
- Document all inputs, outputs, software metadata, references and maintainers in
  `meta.yml`.
- Use `meta` maps for file inputs where sample metadata may be needed.
- Put optional command-line arguments in `task.ext.args`; use `task.ext.prefix`
  for output prefixes.
- Emit `versions.yml` with version strings starting with a numeric version.
- Provide a `stub:` block.
- Provide `tests/main.nf`, `tests/main.nf.test` and snapshot files using small
  test data.
- Run component linting and tests in a fork of `nf-core/modules` before opening
  an upstream pull request.

Current local check:

```console
nf-core modules lint --dir . --local --all --plain-text
```

Summary from the current development tree:

- 900 tests passed.
- 0 tests failed.
- 230 warnings remain.

The warnings are not all equivalent. The important actionable classes are:

- Several new local `meta.yml` files still use the pipeline-local metadata style
  and are flagged by the current `nf-core/modules` JSON schema. Before upstream
  submission, each candidate module must be generated or reshaped in an actual
  `nf-core/modules` checkout and linted there.
- Several modules emit classic `versions.yml` files but do not yet use the newer
  topic-based version emission style expected by recent component guidelines.
- TelomereHunter2 currently uses an upstream Docker image with a `latest` tag,
  which is not suitable for an nf-core component PR.
- ROSE currently uses a GHCR image rather than a Bioconda / BioContainers
  package, so it should remain local for now.
- Warnings from legacy modules bundled in this pipeline should not be confused
  with the status of the new components.

## Candidate Modules

### NucleoATAC

Status: close to upstreamable.

- Local path: `modules/local/nucleoatac`
- Tool package: `nucleoatac=0.3.4` from Bioconda / BioContainers.
- Strengths: has `meta.yml`, `environment.yml`, `versions.yml`, `stub`, nf-test
  harness and compressed large interval outputs.
- Before upstream PR: move to `nf-core/modules/modules/nf-core/nucleoatac/run`,
  rerun lint/tests there, and decide whether the module should track the newer
  Bioconda `nucleoatac=1.0.0` package rather than the historical
  `nucleoatac=0.3.4` package.
- Required cleanup: adapt `meta.yml` to the current upstream component schema,
  check topic-based version emission, and keep all user-tunable options behind
  `task.ext.args`.

### TelomereHunter2

Status: useful locally, not yet ready for upstream without packaging cleanup.

- Local path: `modules/local/telomerehunter2`
- Tool package: currently uses the upstream Docker image
  `fpopp22/telomerehunter2:latest`.
- Strengths: has `meta.yml`, `environment.yml`, `versions.yml`, `stub` and
  nf-test harness.
- Before upstream PR: avoid `latest`, use a pinned Bioconda / BioContainers
  release once available, add or confirm a bio.tools identifier when one exists,
  and rerun lint/tests in `nf-core/modules`.
- Required cleanup: confirm final package route, pin the exact version, adapt
  `meta.yml` to the current upstream component schema, and check topic-based
  version emission.

### QDNAseq

Status: pipeline-specific wrapper around a Bioconductor package.

- Local path: `modules/local/qdnaseq`
- Tool package: `bioconductor-qdnaseq=1.46.0` from Bioconda / BioContainers.
- Strengths: has `meta.yml`, `environment.yml`, `versions.yml`, `stub` and
  nf-test harness.
- Caveat: the module wraps an R helper script to run a complete QDNAseq workflow
  rather than a single upstream executable. This may be acceptable as a local
  pipeline module, but an upstream component may need discussion with
  `nf-core/modules-team` about granularity and test data.
- Required cleanup if proposed upstream: ask first whether the community wants a
  wrapper workflow module or smaller Bioconductor command wrappers; then adapt
  metadata and tests accordingly.

### chromVAR

Status: pipeline-specific wrapper around a Bioconductor workflow.

- Local path: `modules/local/chromvar`
- Tool package: `bioconductor-chromvar` from Bioconda / BioContainers.
- Strengths: has metadata, software environment, version reporting and tests.
- Caveat: like QDNAseq, this wraps an R analysis workflow rather than a single
  command-line tool. It may be better kept local unless the broader nf-core
  community wants a shared chromVAR workflow component.
- Required cleanup if proposed upstream: clarify granularity with the modules
  team, then provide minimal motif/count test data and current-schema metadata.

### ROSE

Status: local-only for now.

- Local path: `modules/local/rose`
- Tool package: uses `ghcr.io/stjude/abralab/rose:v1.3.2`.
- Strengths: has metadata, version reporting and stub support.
- Blocker for upstream: ROSE is not currently consumed from Bioconda /
  BioContainers in this module. A component PR would be stronger after a
  Bioconda recipe or another nf-core-approved packaging route is available.
- Required cleanup if kept local: the local module can still be made cleaner by
  pinning the image, keeping arguments in `task.ext.args`, documenting the GTF to
  ROSE annotation conversion, and maintaining a stub test.

## Pipeline-Specific Glue Components

The following components are useful inside this pipeline but are less likely to
be accepted as standalone upstream modules because they encode pipeline-specific
format conversions or reporting conventions:

- `modules/local/bed_slop`
- `modules/local/bedtools/multicov_counts`
- `modules/local/consensus_super_enhancers`
- `modules/local/gtf_to_rose_annotation`
- `modules/local/samtools/view_outside_regions`
- `modules/local/vcf_filter_regions`
- `modules/local/vcf_stats`

These should still keep nf-core style locally, but they should not be the first
upstream targets.

## Proposed Upstream Order

1. `nucleoatac/run`: first realistic upstream component target.
2. `telomerehunter2`: only after version-pinned packaging is available.
3. `qdnaseq` and `chromvar`: discuss in `#modules` before spending time on PRs.
4. ROSE: keep local until packaging is resolved.

## Immediate Pipeline Actions

For this `nf-core/atacseq` fork, the pragmatic target is:

- keep ROSE, QDNAseq, chromVAR and ATAC-specific glue local;
- make all local modules lint-clean enough for pipeline review;
- upstream only genuinely reusable single-tool wrappers;
- avoid blocking biological validation on component PRs that need community
  discussion.
