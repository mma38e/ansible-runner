# ansible-runner

Personal kitchen-sink Ansible container. Batteries included — Galaxy collections,
STIG hardening roles, and all common Python dependencies pre-installed.

Built on **UBI9** and published to Docker Hub at [`mma38e/ansible-runner`](https://hub.docker.com/r/mma38e/ansible-runner).

**Latest stable:** [![Docker Image Version (latest semver)](https://img.shields.io/docker/v/mma38e/ansible-runner?label=%20&style=flat-square)](https://hub.docker.com/r/mma38e/ansible-runner)
**Development:** [`dev` tag on Docker Hub](https://hub.docker.com/r/mma38e/ansible-runner/tags?name=dev)

---

## Quick start

```bash
# Interactive shell
docker run -it --rm mma38e/ansible-runner:latest

# Run a single command
docker run -it --rm -v $PWD:/runner mma38e/ansible-runner:latest ansible --version

# Mount a project and run a playbook
docker run -it --rm -v $PWD:/runner mma38e/ansible-runner:latest \
    ansible-playbook -i inventory site.yml

# AWX / ansible-runner mode (executes /runner/start.sh)
docker run -it --rm -e RUNNER_MODE=awx -v $PWD:/runner mma38e/ansible-runner:latest
```

## start.sh — self-bootstrapping runner

The repo includes a [`start.sh`](start.sh) template you can copy into any Ansible
project. It detects whether it's running inside or outside the container and
behaves accordingly — no separate `docker run` command needed.

```
your-ansible-project/
├── inventory/
│   └── hosts.yml
├── site.yml
└── start.sh          ← copy from this repo, edit the playbook/inventory vars
```

```bash
# From your workstation — automatically launches the container
./start.sh

# With options
SSH_KEY=~/.ssh/id_rsa EXTRA_VARS="env=prod" ./start.sh

# With a vault password file
VAULT_PASS_FILE=.vault_pass ./start.sh
```

The detection works by checking for `/.dockerenv`, which Docker creates inside
every container. Outside: `docker run` is called and this script is re-executed
inside. Inside: `ansible-playbook` runs directly.

Configurable via environment variables at the top of the script:

| Variable | Default | Purpose |
|---|---|---|
| `ANSIBLE_RUNNER_IMAGE` | `mma38e/ansible-runner:latest` | Image to use |
| `INVENTORY` | `inventory/hosts.yml` | Inventory path |
| `PLAYBOOK` | `site.yml` | Playbook to run |
| `EXTRA_VARS` | _(none)_ | Extra vars string |
| `SSH_KEY` | _(none)_ | Host path to SSH key |
| `VAULT_PASS_FILE` | _(none)_ | Vault password file |

---

## Configuration

The repo includes an [`ansible.cfg`](ansible.cfg) with sensible defaults for
containerized/CI environments — host key checking disabled, YAML output, etc.
Customize as needed for your environment.

---

## What's included

### System tools
`git` · `openssh-clients` · `rsync` · `jq` · `curl` · `sshpass` · `unzip`

### Python packages
See [requirements.txt](requirements.txt) — covers AWS, GCP, Kubernetes, VMware,
CloudStack, Docker, NetBox, Windows WinRM, PostgreSQL, and more.

### Ansible Galaxy collections
See [requirements.yml](requirements.yml).

| Namespace | Collections |
|---|---|
| `ansible.*` | netcommon, posix, utils, windows |
| `awx` | awx |
| `cisco` | ios |
| `community.*` | crypto, docker, general, postgresql |
| `dellemc` | os9, os10 |
| `freeipa` | ansible_freeipa |
| `google` | cloud |
| `kubernetes` | core |
| `ngine_io` | cloudstack |
| `nutanix` | ncp |
| `vmware` | vmware_rest |

### Ansible Galaxy roles

| Role | Purpose |
|---|---|
| `ansible-lockdown.ubuntu22_stig` | Ubuntu 22 DISA STIG hardening |
| `ansible-lockdown.rhel8_stig` | RHEL 8 DISA STIG hardening |
| `ansible-lockdown.rhel9_stig` | RHEL 9 DISA STIG hardening |
| `ansible-lockdown.ubuntu20_stig` | Ubuntu 20 DISA STIG hardening |

---

## Development workflow

Push to **`develop` branch** for testing:
```bash
git checkout develop
git push origin develop
# Builds and pushes as `dev` tag on Docker Hub
docker pull mma38e/ansible-runner:dev
```

Push to **`main` branch** + tag releases for production:
```bash
git checkout main
git merge develop    # merge stable code to main
git tag v1.2.3
git push --all --tags
# Builds and pushes as v1.2.3, 1.2, 1, and latest
```

All builds are tracked in [GitHub Actions](https://github.com/mma38e/ansible-runner/actions).

---

## Building locally

For manual testing before pushing:

```bash
# Build only
./build-n-push.bash --build

# Build and push (useful for offline testing, but prefer GitHub Actions)
DOCKER_HUB_USER=mma38e ./build-n-push.bash --all
```

For normal development: push to `develop` branch and let GitHub Actions handle building/publishing. See **Development workflow** above.

---

## Adding dependencies

| What | File |
|---|---|
| Galaxy collections | `requirements.yml` → `collections:` |
| Galaxy roles | `requirements.yml` → `roles:` |
| Python packages | `requirements.txt` |
| System packages | `Dockerfile` → `dnf install` block |

After editing, push to `develop` branch and GitHub Actions will build and test it as the `dev` tag:

```bash
git add -A
git commit -m "Add X dependency"
git push origin develop
# Watch the build at https://github.com/mma38e/ansible-runner/actions
```
