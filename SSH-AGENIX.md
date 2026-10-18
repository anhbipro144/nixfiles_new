# SSH and agenix

Linux is provisioned first. The Mac's existing SSH keys and hosts have not been inspected, so `neo@mac` currently receives only the shared SSH defaults and no Linux key secrets or host aliases.

## Recovery identity

Each machine needs a separate, unencrypted Ed25519 SSH key for agenix at `~/.config/agenix/identity`, mode `0600`. It is only a decryption identity; do not use it for SSH login. The recipient public key belongs in `secrets/ssh/secrets.nix`; the private identity must stay outside Git and `/nix/store`.

For a new machine, create the identity with `ssh-keygen -t ed25519 -N '' -C agenix-<machine> -f ~/.config/agenix/identity`, derive its public key with `ssh-keygen -y -f ~/.config/agenix/identity`, and add that public recipient only to the secrets the machine needs. Make and verify a recoverable backup before activating agenix.

### Cloud backup and restore

The Linux identity backup is age passphrase-encrypted and stored outside this repository at:

- Encrypted file to upload: `~/.local/state/agenix-recovery/identity.age`
- Local passphrase file: `~/.local/state/agenix-recovery-secret/passphrase`

The passphrase file is mode `0600` in a mode `0700` directory. Save its contents in a password manager that is independent of Google Drive. Upload only `identity.age`; never upload the passphrase file. Do not paste the passphrase into chat. Keep the local passphrase file until the downloaded cloud copy has been verified and the passphrase is safely stored elsewhere.

To verify a downloaded copy without displaying the private identity, replace the download path below and run locally. `age` prompts for the passphrase without echoing it; the decrypted identity is written only to the user's private runtime directory:

```sh
umask 077
verify_dir=$(mktemp -d "/run/user/$(id -u)/agenix-restore.XXXXXX")
chmod 700 "$verify_dir"
trap 'rm -rf "$verify_dir"' EXIT
age -d -o "$verify_dir/identity" /path/to/downloaded/identity.age
chmod 600 "$verify_dir/identity"
ssh-keygen -y -f "$verify_dir/identity" > "$verify_dir/identity.pub"
ssh-keygen -lf "$verify_dir/identity.pub"
```

The fingerprint must be `SHA256:q4kyMnsrUp+lDHk6b4Eo1BWDjZ0E3vg+UrmbMVnIG7M`, matching the Linux recipient. The downloaded Google Drive copy was verified on 2026-10-18: SHA-256 `99f699bfbc697a613b77e8f008553846b485d17729a2680cc705635f883bfd1a`. Decryption succeeded, the recovered identity matched this fingerprint, and it decrypted all three Linux SSH secrets with matching original key fingerprints. To verify the recovered identity still decrypts all three SSH keys, decrypt each `.age` file with `age -d -i "$verify_dir/identity" -o "$verify_dir/<name>" secrets/ssh/<name>.age`, then compare `ssh-keygen -lf "$verify_dir/<name>"` with the fingerprints below. Do not print or store the recovered private files outside this temporary directory.

On a fresh machine, restore the repository and matching identity before switching Home Manager. The repository copy is the same passphrase-encrypted ciphertext as the cloud backup at `secrets/recovery/identity.age`; its SHA-256 is `99f699bfbc697a613b77e8f008553846b485d17729a2680cc705635f883bfd1a`. The plaintext identity and recovery passphrase are not stored in Git.

#### Restore the Linux identity from Git

Run from the repository root on a fresh Linux machine. `age` prompts for the recovery passphrase without echoing it. This procedure checks the ciphertext hash and Linux recipient fingerprint, writes plaintext only to the user's private runtime directory, and refuses to overwrite an existing identity.

```sh
set -eu
umask 077
printf '%s  %s\n' 99f699bfbc697a613b77e8f008553846b485d17729a2680cc705635f883bfd1a secrets/recovery/identity.age | sha256sum --check
restore_dir=$(mktemp -d "/run/user/$(id -u)/agenix-restore.XXXXXX")
chmod 700 "$restore_dir"
trap 'rm -rf "$restore_dir"' EXIT
age -d -o "$restore_dir/identity" secrets/recovery/identity.age
chmod 600 "$restore_dir/identity"
ssh-keygen -y -f "$restore_dir/identity" > "$restore_dir/identity.pub"
fingerprint=$(ssh-keygen -lf "$restore_dir/identity.pub" | awk '{print $2}')
test "$fingerprint" = 'SHA256:q4kyMnsrUp+lDHk6b4Eo1BWDjZ0E3vg+UrmbMVnIG7M'
install -d -m 700 "$HOME/.config/agenix"
test ! -e "$HOME/.config/agenix/identity" && test ! -L "$HOME/.config/agenix/identity"
install -m 600 "$restore_dir/identity" "$HOME/.config/agenix/identity"
```

This restores only the Linux decryption identity. Keep it outside the repository and `/nix/store`. The existing cloud backup remains a separate recovery copy. Agenix decrypts at activation into the platform runtime directory and links configured key paths under `~/.ssh`; Linux uses a systemd user service and macOS uses a launchd agent. Recheck after login and reboot before relying on it.

If the decryption identity is lost, recover its backup first. Without a matching identity or backup, existing `.age` files cannot be recovered; create a new identity and rotate/re-encrypt the affected SSH keys only after access to their remote accounts is secured.

## Add a host or key

1. Add the host under `programs.ssh.settings` in `ssh.nix`, using the machine's real identity path. Keep host-key verification and known-host files intact.
2. Generate or select the SSH login key on the target machine. Do not reuse the agenix decryption identity as a login key.
3. Add that machine's public recipient only to the secret entries it needs in `secrets/ssh/secrets.nix`.
4. From `secrets/ssh`, encrypt the key through agenix without placing its contents in a command argument:

   ```sh
   AGENIX_RULES="$PWD/secrets.nix" agenix -e new_key.age < ~/.ssh/new_key
   ```

5. Declare the encrypted file under `age.secrets` in `ssh.nix`, with a stable path and mode `0400`. Verify decryption into a private temporary directory, compare the resulting public-key fingerprint, and run `agenix --check` before activation.

When changing recipients, update only the relevant `publicKeys` list, then run `agenix -r` from `secrets/ssh` and verify every affected secret. Adding a recipient grants that machine access to the corresponding private key. Removing a recipient does not revoke any copy already decrypted by that machine.

## Remove or rotate a key

Remove its host mapping and `age.secrets` declaration after confirming nothing else uses its path. Remove the corresponding recipient, rekey with `agenix -r`, and verify the remaining machines can still decrypt. Keep the original login key until its replacement has been tested against every required remote account. Do not remove remote authorized keys automatically.

## Linux cutover and rollback

Linux cutover completed on 2026-10-18. The original `~/.ssh/config`, `id_ed25519`, `neo_ubuntu`, and `neo_ubuntu.pem` were moved into `/home/neo/.local/state/ssh-migration.t2SbiJeL/pre-agenix-live` before activation and verified against the separate secure backup. Public keys, `known_hosts`, `known_hosts.old`, and `test_shine` remain in place. The `my-ec2` host alias has since been removed; the `neo_ubuntu.pem` identity remains managed at its existing path pending any separate decision to retire it.

The guarded cutover commands applied were:

```sh
set -eu
cutover=/home/neo/.local/state/ssh-migration.t2SbiJeL/pre-agenix-live
install -d -m 700 "$cutover"
for name in config id_ed25519 neo_ubuntu neo_ubuntu.pem; do
  test -f "$HOME/.ssh/$name" && test ! -L "$HOME/.ssh/$name"
  test ! -e "$cutover/$name" && test ! -L "$cutover/$name"
done
for name in config id_ed25519 neo_ubuntu neo_ubuntu.pem; do
  mv "$HOME/.ssh/$name" "$cutover/$name"
done
home-manager switch --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@main"
```

Then verify `systemctl --user status agenix.service`, key modes/fingerprints, and `ssh -G` for all four aliases before any remote authentication test.

To roll back, run these commands. They stop if any path is a regular file or has an unexpected symlink target, rather than overwriting it:

```sh
set -eu
cutover=/home/neo/.local/state/ssh-migration.t2SbiJeL/pre-agenix-live
systemctl --user stop agenix.service || true
home-manager switch --rollback
for name in config id_ed25519 neo_ubuntu neo_ubuntu.pem; do
  path="$HOME/.ssh/$name"
  if [ -L "$path" ]; then
    target=$(readlink -- "$path")
    case "$target" in
      /nix/store/*-home-manager-files/*|/run/user/*/agenix/*) rm -- "$path" ;;
      *) printf 'Unexpected symlink target for %s; stop and inspect it.\n' "$path" >&2; exit 1 ;;
    esac
  elif [ -e "$path" ]; then
    printf 'Refusing to overwrite %s; stop and inspect it.\n' "$path" >&2
    exit 1
  fi
done
for name in config id_ed25519 neo_ubuntu neo_ubuntu.pem; do
  mv "$cutover/$name" "$HOME/.ssh/$name"
done
chmod 700 "$HOME/.ssh"
```

Then verify the restored fingerprints and SSH config. This does not alter the separate original-file backup or `known_hosts`.

## Current migration status

- On 2026-10-18, `id_ed25519.age` and `neo_ubuntu.age` were renamed to `neo_ONE_key.age` and `neo_personal_key.age`; their ciphertext contents and Linux recipient were preserved. The SSH host aliases now reference the renamed paths, and the old private-key symlinks were removed after validation. The `.pem` secret and hostnames/options were unchanged. Public keys are now named `neo_ONE_key.pub` and `neo_personal_key.pub`.
- Original public-key copies are preserved in `~/.ssh/.key-rename-backup-2026-10-18/`. To roll back the path rename, run `home-manager switch --rollback`, then restore the public-key filenames with `cp -p "$HOME/.ssh/.key-rename-backup-2026-10-18/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"` and `cp -p "$HOME/.ssh/.key-rename-backup-2026-10-18/neo_ubuntu.pub" "$HOME/.ssh/neo_ubuntu.pub"`. The previous Home Manager generation restores its SSH config and agenix paths.
- The Linux recipient is a dedicated Ed25519 identity. Its fingerprint is `SHA256:q4kyMnsrUp+lDHk6b4Eo1BWDjZ0E3vg+UrmbMVnIG7M`.
- Linux secrets cover `neo_ONE_key`, `neo_personal_key`, and `neo_ubuntu.pem`. `test_shine` remains unmanaged because its purpose is unknown.
- The Linux key paths were renamed without key rotation: `id_ed25519` → `neo_ONE_key` (`SHA256:ErHzkdUtj/+SFszY+gLN3eC8ELfPQOqjiRUulT/Khu8`) and `neo_ubuntu` → `neo_personal_key` (`SHA256:Bg1F8xC/TqoPQPEpnsDQXwpeeK0YYAXYtRF4N8OL7Bg`). `neo_ubuntu.pem` remains unchanged (`SHA256:aROvEFk9NgpvlArBP1O81pTtaq9aDrPQ5fw73/hRUmk`).
- Linux SSH aliases for `homelab`, `github.com-personal`, and `github.com` are declared in `ssh.nix`. The `my-ec2` alias was removed; `known_hosts` remains user-managed and writable.
- The passphrase-encrypted cloud backup and downloaded copy are verified; see “Cloud backup and restore.” Linux Home Manager activation succeeded. The agenix oneshot completed with exit status 0, decrypted all three keys to mode `0400`, and their fingerprints matched the originals. Both GitHub aliases and `homelab` authenticated; the homelab test ran a harmless remote `true` command with strict host-key checking. `my-ec2` timed out before its alias was removed. The original config and login keys remain in `/home/neo/.local/state/ssh-migration.t2SbiJeL/pre-agenix-live` for rollback.
- macOS evaluation is possible from Linux, but its keys, host inventory, activation, login, reboot, and SSH connections still need validation on the Mac.
