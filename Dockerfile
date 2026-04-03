FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL maintainer="Michael Amireh" \
      description="Personal Ansible kitchen-sink runner" \
      org.opencontainers.image.source="https://github.com/mma38e/ansible-runner"

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install EPEL and system packages in a single layer
RUN dnf install -y \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    && dnf install -y --setopt=install_weak_deps=False --nodocs \
        glibc-langpack-en \
        git \
        openssh-clients \
        rsync \
        jq \
        unzip \
        python3 \
        python3-pip \
        sshpass \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install Ansible and Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir --ignore-installed -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Install Ansible Galaxy collections
COPY requirements.yml /root/requirements.yml
COPY ansible.cfg /etc/ansible/ansible.cfg
RUN ansible-galaxy collection install --force-with-deps -r /root/requirements.yml \
    && ansible-galaxy role install --ignore-errors -r /root/requirements.yml

WORKDIR /runner/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
