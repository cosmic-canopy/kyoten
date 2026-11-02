# kyotenengine.com: the website, its subdomains, provisioning and deployment

**Status:** draft, deferred past the first slice to KYR-39. These are questions, not decisions.

## What the vision asks

- **kyotenengine.com**, a domain the owner already has, with **provisioning and automated deployment**.
- **The home page is the marketing and the getting started**, much like kama's website.
- **Subdomains** for various purposes.

## What already exists: how kama-lang.org is run

Everything below is in the kama repo, and works today:

- **Provisioning as code.** `kama/provisioning/pages/main.tf` (OpenTofu, the Cloudflare provider) declares the Pages
  project, the custom domains (apex and `www`), and the DNS records. `./ops provision` runs `tofu init` and `tofu apply`,
  with `CLOUDFLARE_API_TOKEN` and `TF_VAR_account_id`/`TF_VAR_zone_id` loaded from a gitignored `.env`.
- **Subdomains already in that state:** `registry.kama-lang.org` is a second Pages project; `dl.kama-lang.org` is an
  R2 bucket's custom domain for package tarballs. **Every record of the zone lives in one state**, because "two states
  managing one zone is how records get overwritten". Use the project's computed `subdomain`, never a hard-coded
  `<name>.pages.dev`, because those names are globally unique and get suffixed.
- **The site is built from the docs.** `tools/build-site` (node, `tools/site/build.mjs`) assembles `_site` from `site/`
  (styles, scripts, assets, `CNAME`) and the `docs/` pages, so a docs edit is a site edit.
- **Deployment.** `.github/workflows/deploy-site.yml` runs on every push to `main` that touches the site's inputs, and
  deploys with `wrangler pages deploy`, using `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` repository secrets.
  `./ops deploy-site` does the same by hand.
- **The install scripts** (`install.sh`, `install.ps1`) and `llms.txt` are published with the site, and resolve the
  latest release from GitHub's API. `kama/docs/PUBLISHING.md` records the go-live order: the repository public first,
  then the release, then the site, because the site serves whatever release is latest.

## The questions

1. **The same stack as kama?** Cloudflare Pages, R2 and DNS through OpenTofu, deployed from GitHub Actions, run from
   an `./ops` script. One account for both, or separate? Is kyotenengine.com's DNS on Cloudflare today, and if not,
   is it moved there?
2. **The subdomain plan.** Candidates, to be confirmed or cut:
   - `kyotenengine.com` and `www`: marketing and getting started;
   - `docs.`: the engine's docs (or under the apex, as kama does);
   - `play.`: hosted web games ([marketplace.md](marketplace.md));
   - `market.` or `store.`: the marketplace;
   - `api.` and the networking backend's hosts (relay, matchmaking) ([networking.md](networking.md));
   - `dl.`: engine builds for the version manager ([version-manager.md](version-manager.md));
   - `status.`, and a blog or changelog.
   Which exist on day one, and is each a static site, a worker, or a service?
3. **Where the site's source lives.** In this repository, built from `docs/` as kama's is, so the engine's docs and its
   site cannot drift? Or a separate repository, with the platform's pages (marketplace, accounts) in another, since
   those are a product of their own?
4. **The generator.** Reuse kama's `tools/site` (node), or build the site with kyoten itself (the home page could run
   a live kyoten scene in WebGPU, which is both the demo and the proof of "light on the web")?
5. **What the home page says and shows.** The pitch against Unity, Unreal and Godot; a live demo; getting started
   (install the version manager, create a game, run it on the web); the example games (each its own repository); docs.
6. **Deploy and previews.** On push to `main` as kama does, plus preview deployments for pull requests?
7. **Before there is an engine.** A landing page and a waitlist now, or nothing until the first vertical slice runs?
8. **Secrets and ownership.** Who holds the Cloudflare tokens, where `.env` lives, and which repository secrets CI
   needs.

## Decided

- **2026-11-01, the owner: deferred past the first slice** when the spike was narrowed
  ([../SPIKE.md](../SPIKE.md#narrowed-2026-11-01)). It is taken up with KYR-39. Question 7, a landing page before
  there is an engine, can be pulled forward whenever the owner wants, since nothing in the engine waits on it.
