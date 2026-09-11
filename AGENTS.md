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
- If the `IS_DDEV_PROJECT` environment variable is set or the `ddev` CLI is unavailable, you are operating inside a DDEV container. In this case, **never** execute `ddev` commands. Instead, instruct the user to run any required `ddev` commands on their host machine and, if needed, share the output.

## Shell Compatibility
- All shell commands in `install.yaml`, `config.*.yaml`, and hooks must be **macOS (BSD) and Linux (GNU) compatible**.

## Writing bats tests for the SAML IdP service

The `saml-idp` service is gated behind an optional Docker Compose profile. A plain `ddev restart` does not start it unless an override file is used. Tests that need the container must use:

```bash
ddev restart && ddev start --profiles=saml-idp
```

`ddev restart` alone reuses already-running services; since `saml-idp` is not active by default, the container will not exist and any subsequent commands targeting it will fail.

Note: `ddev restart` (including `--no-cache`) does not rebuild profile-gated services ([ddev/ddev#8817](https://github.com/ddev/ddev/issues/8817)). While targeted rebuilding via `ddev utility rebuild -s <service>` (or `ddev debug rebuild -s <service>`) for profile-gated services was fixed in DDEV v1.25.3 ([ddev/ddev#8463](https://github.com/ddev/ddev/pull/8463)), `ddev restart` does not support `--profiles` yet ([ddev/ddev#7904](https://github.com/ddev/ddev/issues/7904)). Therefore, `ddev restart && ddev start --profiles=saml-idp` is required after rebuilding to bring the container up with all dependencies.
