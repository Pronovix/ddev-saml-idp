# Agent Guidelines

When working on this project, please adhere to the following guidelines:

## Architectural & Project Foundations
To optimize token usage, do not read the entire `README.md` unless you need specific, step-by-step Drupal configuration steps or debugging commands. Instead, use these core architectural foundations:
- **Project Role:** This is a DDEV Add-on provisioning a local **SimpleSAMLphp Identity Provider (IdP)** container as a dedicated service.
- **Dynamic Hostnames & Routing:** The IdP runs at `https://idp.<project>.ddev.site/simplesaml/`. Hostnames are resolved dynamically using environment variables (`SAML_IDP_PRIMARY_HOST`, `SAML_SP_PRIMARY_HOST`). Do not hardcode hostnames in configurations.
- **File Access & Mounts:** 
  - Configuration, metadata, and certificates are stored in `.ddev/saml-idp/`.
  - Within the main DDEV web container, the `.ddev/` directory is mounted at `/mnt/ddev_config/`. Therefore, the web application accesses SAML certificates via paths like `/mnt/ddev_config/saml-idp/certs/sp.key` or `file:/mnt/ddev_config/saml-idp/certs/sp.key`.
- **Settings Overrides:** The installer modifies `settings.local.php` or `project.local.settings.php` between the markers:
  `// --- BEGIN DDEV SAML IDP OVERRIDES ---` and `// --- END DDEV SAML IDP OVERRIDES ---`.

## Ignoring `.ddev`
- Do not modify or perform extensive searches within the `.ddev` directory. This directory contains the installed version of this addon, which is used for testing changes. Focus your work on the source code outside of this directory.

## DDEV Environment
- This project is designed to be worked on within a DDEV environment.
- If the `IS_DDEV_PROJECT` environment variable is set, or if the `ddev` command is not available, you are already running inside a DDEV container. In this case, **never** attempt to execute commands prefixed with `ddev` (such as `ddev ...`); instead, run those commands directly (e.g., run `composer` or `drush` directly without the `ddev` prefix).
