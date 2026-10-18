# About this fork

This repository hosts [CVAurum](https://github.com/akhil-dara/cvaurum), by Akhil Dara, at
https://cv.hirepotential.co.uk. HirePotential's apps link to it as their free CV builder.

- **What runs there:** upstream's `main`, unmodified. `.github/workflows/deploy.yml` builds it
  every day at 05:00 UTC, runs upstream's typecheck and tests, and deploys only if they pass.
  The job summary of each run names the upstream commit that was deployed.
- **Our only changes** are hosting: this file, the deploy workflow and `CNAME`. Nothing in the
  application is changed, so the source link on the site (upstream's repository) is the source
  of what's served.
- **Licence:** CVAurum is AGPL-3.0 (from 23 Sep 2026; MIT before that). See `LICENSE` and
  `NOTICE`. If we ever change the application code, the site must link to this repository
  instead, and those changes are AGPL too.
- **Deploy a specific version:** Actions › Deploy upstream CVAurum › Run workflow, and give an
  upstream commit (useful to roll back if upstream breaks something its tests don't catch).
- **If a deploy fails:** the site keeps the last good version. GitHub emails the failure.
- **Security headers:** GitHub Pages ignores upstream's `public/_headers`, so the same headers
  (Content-Security-Policy and the rest; HSTS without `includeSubDomains; preload`) are set by a
  Cloudflare Response Header Transform Rule on `cv.hirepotential.co.uk`. The daily workflow's `headers` job
  (`.github/headers/check.sh`) fails, and GitHub emails you, if upstream changes its `_headers`
  or the live site stops sending what the rule sets; the run summary shows the difference.
