[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/Pronovix/ddev-saml-idp/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/Pronovix/ddev-saml-idp/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/Pronovix/ddev-saml-idp)](https://github.com/Pronovix/ddev-saml-idp/commits)
[![release](https://img.shields.io/github/v/release/Pronovix/ddev-saml-idp)](https://github.com/Pronovix/ddev-saml-idp/releases/latest)

# DDEV Saml Idp

## Overview

This add-on integrates Saml Idp into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get Pronovix/ddev-saml-idp
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Saml Idp |
| `ddev logs -s saml-idp` | Check Saml Idp logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.saml-idp --saml-idp-docker-image="ddev/ddev-utilities:latest"
ddev add-on get Pronovix/ddev-saml-idp
ddev restart
```

Make sure to commit the `.ddev/.env.saml-idp` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `SAML_IDP_DOCKER_IMAGE` | `--saml-idp-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@Pronovix](https://github.com/Pronovix)**
