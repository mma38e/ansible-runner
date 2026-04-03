# ansible-runner

Personal kitchen-sink Ansible container. Batteries included — Galaxy collections,
STIG hardening roles, and all common Python dependencies pre-installed.

Built on **UBI9** and published to Docker Hub at `mma38e/ansible-runner`.

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
| `ansible-lockdown.ubuntu20_stig` | Ubuntu 20 DISA STIG hardening |
| `ansible-lockdown.RHEL8-STIG` | RHEL 8 DISA STIG hardening |
| `ansible-lockdown.RHEL9-STIG` | RHEL 9 DISA STIG hardening |

---

## Building and pushing

```bash
# Build only
./build-n-push.bash --build

# Build and push to Docker Hub
docker login
./build-n-push.bash --all

# Override username or image name
DOCKER_HUB_USER=myuser IMAGE_NAME=my-runner ./build-n-push.bash --all
```

Version is controlled by the [`version`](version) file.

---

## Adding dependencies

| What | File |
|---|---|
| Galaxy collections | `requirements.yml` → `collections:` |
| Galaxy roles | `requirements.yml` → `roles:` |
| Python packages | `requirements.txt` |
| System packages | `Dockerfile` → `dnf install` block |

After editing, rebuild the image with `./build-n-push.bash --build`.
