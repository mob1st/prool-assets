# Publish Assets to an R2-Backed CDN

Merged assets are published to a Cloudflare R2 bucket and served from the public CDN root `https://assets.playprool.com`. Repository paths are reflected directly under that CDN root, so `images/country/england/tournaments/premier-league/logo/2026-27.svg` is served as `https://assets.playprool.com/images/country/england/tournaments/premier-league/logo/2026-27.svg`.

Assets are organized by semantic entity rather than provider identifier. Versioning should be visible in the path or filename so new published assets can be added without overwriting existing URLs; for example, tournament logos can use an edition filename such as `images/country/england/tournaments/premier-league/logo/2026-27.svg`, and team jerseys can use `images/country/england/teams/arsenal/jersey/2026-27.svg`.

This keeps public URLs stable, cache-friendly, and understandable from the domain alone. The trade-off is that renaming folders or changing slug conventions becomes a public URL change, so path names should be reviewed as part of asset changes.
