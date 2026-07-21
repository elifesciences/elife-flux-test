# Minimal git "smart HTTP" server used by the end-to-end tests (see
# ../run_cluster_in_kind.sh) to serve the developer's *local* repository to the
# Flux running inside the KinD cluster. Flux only supports http/https/ssh Git
# sources, so a plain `git daemon` (git:// protocol) cannot be used.
#
# It serves every git directory found under /repo, read-only and WITHOUT
# authentication. This is safe only because it is reachable exclusively from the
# local KinD docker network - never expose it anywhere else.
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git apache2 \
 && rm -rf /var/lib/apt/lists/* \
 && a2enmod cgid alias env >/dev/null \
 # the bind-mounted repo is owned by the host user, not the container user
 && git config --system --add safe.directory '*'

# Expose every git dir under GIT_PROJECT_ROOT over the smart HTTP protocol.
RUN printf '%s\n' \
    'SetEnv GIT_PROJECT_ROOT /repo' \
    'SetEnv GIT_HTTP_EXPORT_ALL' \
    'ScriptAlias /git/ /usr/lib/git-core/git-http-backend/' \
    '<Directory "/usr/lib/git-core">' \
    '  Require all granted' \
    '  Options +ExecCGI' \
    '</Directory>' \
    > /etc/apache2/conf-available/git.conf \
 && a2enconf git >/dev/null

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
