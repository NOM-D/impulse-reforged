# Deploying through playit SFTP

This manual workflow uploads runtime files from `main` to
`/garrysmod/gamemodes/impulse-reforged/` through the configured playit SFTP
tunnel. The tunnel must forward TCP to the Wings SFTP service.

## One-time setup

In this repository, open Settings > Secrets and variables > Actions.
Add these repository secrets:

| Secret | Value |
| --- | --- |
| `SFTP_USERNAME` | Complete username from the target server's Pterodactyl Settings > SFTP Details, including the server suffix |
| `SFTP_PASSWORD` | Password for that Pterodactyl account |
| `SFTP_HOST_KEY_SHA256` | The SHA256 fingerprint of the Wings SFTP host key |

Open your trusted SSH session to the Ubuntu game-server VM. Obtain the
fingerprint by running this on that VM (using the default Wings SFTP port):

```bash
ssh-keyscan -p 2022 127.0.0.1 2>/dev/null | ssh-keygen -lf - -E sha256
```

Copy only the `SHA256:...` value into `SFTP_HOST_KEY_SHA256`, not the key size,
hostname, or parentheses. This is a public fingerprint, not a password. The
workflow verifies this fingerprint before sending the login password.

## Deploy

1. Merge the deployment workflow into `main`.
2. Back up the gamemode folder before updating an existing installation.
3. Stop the target game server in Pterodactyl to avoid loading partially updated code.
4. Open Actions > Deploy to Pterodactyl > Run workflow, select `main`, and run it.
5. Wait for a successful run, verify the files in Pterodactyl, then start the server.

Only `content/`, `entities/`, `gamemode/`, `plugins/`, `impulse-reforged.txt`,
`version.txt`, and `LICENSE` are uploaded. The workflow creates the destination
folder if needed and overwrites matching regular files inside it. It does not
upload repository metadata, docs, or deployment credentials.

This is one-way file deployment. It does not delete files removed from GitHub,
save server-side edits back to GitHub, or stop/start/restart the server. A failed
upload may leave a mix of old and new files; keep the game stopped, resolve the
failure, and rerun before starting it. Local edits to managed files are overwritten.

The repository is the impulse-reforged framework. Uploading it does not configure
a roleplay schema, database, additional dependencies, or the server startup gamemode.

Validation before release checks the upload logic without connecting to the live
server. A real deployment still requires the secrets and a successful manual run.
