# Prool Assets

Prool Assets is the context for curated static files that are reviewed in Git and published for the Prool app through the public asset CDN.

## Language

**Asset**:
A reviewed static file owned by Prool and served by the public asset CDN.
_Avoid_: Media, blob, upload

**Image Asset**:
An asset that visually represents product content, such as a logo, jersey, icon, or illustration.
_Avoid_: Image, picture

**Document Asset**:
An asset that publishes a document for users to read, such as terms and conditions or a privacy policy.
_Avoid_: PDF, legal file

**Data Asset**:
An asset that publishes static, public, cacheable structured data.
_Avoid_: API response, catalog data

**Animation Asset**:
An asset that publishes static motion content, such as a Lottie animation or short media export.
_Avoid_: Motion file, animation file

**Source Asset**:
An editable source file used to produce a public asset.
_Avoid_: Design source, working file

**Published Asset**:
An asset that has been merged and made available from the public asset CDN.
_Avoid_: Uploaded file, deployed image

**Public Asset URL**:
An absolute HTTPS URL rooted at `https://assets.playprool.com` that points to a published asset.
_Avoid_: Image URL, CDN URL

**CDN Path**:
The path under `https://assets.playprool.com` where a published asset is available. CDN paths mirror repository paths.
_Avoid_: Object key, bucket path

**Semantic Path**:
A repository path organized by the thing the asset represents, such as country, tournament, team, logo, jersey, or edition.
_Avoid_: Provider path, arbitrary folder

**Asset Version**:
The path segment or filename portion that distinguishes one published asset version from another.
_Avoid_: Revision, overwrite

**Country**:
A geographic grouping used to organize assets for tournaments and teams.
_Avoid_: Nation

**Tournament**:
A football competition whose assets may include logos or related imagery.
_Avoid_: Competition, league

**Edition**:
A season-specific or cycle-specific version of a tournament or team asset.
_Avoid_: Season version

**Team**:
A football club or side whose assets may include jerseys, logos, or related imagery.
_Avoid_: Club

**Jersey**:
A team shirt image used for product display.
_Avoid_: Kit, shirt
