# Prool Assets

Reviewed static assets for the Prool app.

Assets in this repository are published after merge to a Cloudflare R2 bucket and served from:

```text
https://assets.playprool.com
```

Repository paths are public paths. If a file exists at:

```text
images/country/england/teams/arsenal/jersey/2026-27.svg
```

it is expected to be served at:

```text
https://assets.playprool.com/images/country/england/teams/arsenal/jersey/2026-27.svg
```

## Path Convention

Organize assets by the semantic entity they represent, not by provider IDs or source-system naming.

Top-level folders group assets by family:

```text
images/      image assets such as logos, jerseys, icons, and illustrations
documents/   public document assets such as legal PDFs
animations/  animation assets such as Lottie or short media exports
data/        static public JSON data
fonts/       font files
```

```text
images/
  country/
    <country-slug>/
      tournaments/
        <tournament-slug>/
          <asset-kind>/
            <version>.<ext>
      teams/
        <team-slug>/
          <asset-kind>/
            <version>.<ext>
```

Examples:

```text
images/country/england/tournaments/premier-league/logo/2026-27.svg
images/country/england/teams/arsenal/jersey/2026-27.svg
documents/legal/terms-and-conditions/2026-06-26.pdf
documents/legal/privacy-policy/2026-06-26.pdf
```

Use the edition as the version when the asset is season-specific, such as `2026-27`. For assets that are not tied to a season or edition, use an explicit stable version such as `v1`, `v2`, or `v3`.

Use the effective date as the version for legal documents, such as `2026-06-26.pdf`.

## Naming Rules

- Use existing Prool catalog keys for entity folders when they exist, such as `aston_villa` or `manchester_united`.
- Use kebab-case for new entity folders that do not yet have a canonical catalog key.
- Use only lowercase ASCII letters, numbers, underscores, and hyphens in path segments.
- Do not use spaces.
- Do not use provider IDs in public paths.
- Use singular asset-kind folders, such as `logo` and `jersey`.
- Keep slugs stable after publication.
- Prefer existing product or catalog terms when a slug already exists.
- Review path names carefully because renaming a published path changes the public URL.

## Versioning Rules

Published asset URLs are immutable. Add a new version instead of replacing an existing published file.

Good:

```text
images/country/england/teams/arsenal/jersey/2026-27.svg
images/country/england/teams/arsenal/jersey/2027-28.svg
```

Avoid:

```text
images/country/england/teams/arsenal/jersey/current.svg
```

If a file has already been published and needs correction, add a new version and update consuming catalog data to point at the new Public Asset URL.

## File Formats

Use the format that best matches the asset:

- `svg` for reviewable vector assets such as logos, icons, and simplified jerseys.
- `png`, `webp`, `avif`, `jpg`, or `jpeg` for raster exports.
- `pdf` for published document assets.
- `json` for static public data and Lottie JSON when the file is reasonably reviewable.
- `lottie`, `mp4`, `webm`, or `mov` for packaged animation and media exports.
- `woff2`, `woff`, `ttf`, or `otf` for fonts.
- Editable source files such as `psd`, `ai`, `fig`, `sketch`, or `afdesign` may be stored when needed to reproduce exports.

SVG and JSON files remain normal Git text files so reviewers can inspect changes. Binary exports, fonts, documents, media, and editable source files are tracked with Git LFS via `.gitattributes`.

Static JSON is public and cacheable. Do not use this repository as a substitute for backend-owned catalog data or user-specific API responses.

## Legal Documents

Legal documents may be published here when they are public artifacts, such as terms and conditions or a privacy policy.

```text
documents/legal/terms-and-conditions/2026-06-26.pdf
documents/legal/privacy-policy/2026-06-26.pdf
```

Use effective dates for legal document versions. Never overwrite a published legal document. The application or backend should reference the exact Public Asset URL for the currently effective version, while user acceptance state remains backend-owned.

## Git LFS

Install Git LFS before adding binary asset or source files:

```sh
git lfs install
```

The repository tracks binary exports, fonts, documents, media, and editable source files through Git LFS. After adding a binary asset, confirm it is stored as an LFS pointer before opening a pull request:

```sh
git lfs status
```

## Adding an Asset

1. Read the Linear ticket and use the identifier and branch name provided there.
2. Choose the semantic path for the asset.
3. Add the new file as a new version.
4. Confirm the path maps to the intended Public Asset URL.
5. Do not overwrite an existing published version.
6. Open a pull request for review.

## Deployment

Deployment is intentionally merge-driven. After a pull request is merged, automation syncs repository assets to Cloudflare R2, where they are served through the public asset CDN.

Cloudflare account setup and merge-time deployment automation are tracked separately from the repository conventions.
