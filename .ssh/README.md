-----

# 🔑 SSH Key Setup for the Pi Cluster

Secure, passwordless access is managed using SSH keys. The recommended and most secure method is to use a password manager like **1Password** to store your private keys and act as your SSH agent.

This guide details the manual process of managing SSH keys. Understanding this process is helpful as it forms the basis of how tools like 1Password's SSH agent work.

## \#\# 1. Generating Your SSH Key

First, you'll need an SSH key pair on your main computer. The modern **`ed25519`** algorithm is recommended for its security and performance.

You can run `ssh-keygen` to be guided through an interactive setup, or use the command below for a non-interactive setup.

```bash
# Generate a new ed25519 key and save it as pi_cluster_key in ~/.ssh/
ssh-keygen -t ed25519 -f ~/.ssh/pi_cluster_key -C "your_email@example.com"
```

  * **`-t ed25519`**: Specifies the algorithm.
  * **`-f ~/.ssh/pi_cluster_key`**: Sets the filename. Naming the key upon creation is the cleanest method.
  * **`-C "..."`**: Adds a comment for easy identification.

### \#\#\# Using a Passphrase (Recommended)

When prompted, you should add a passphrase to your private key. This provides a critical layer of security.

To use a passphrase-protected key without re-typing it for every connection, you use an **SSH agent**. The standard `ssh-agent` securely holds your decrypted key in **memory** for your terminal session. A more secure alternative like the **1Password SSH agent** keeps the key encrypted in its vault and uses biometric authentication.

## \#\# 2. Adding Your Public Key to the Pis

You only need to add your **public key** (e.g., `pi_cluster_key.pub`) to the Raspberry Pis.

### \#\#\# Method A: During Initial Setup (Raspberry Pi Imager)

For fresh Pis, this is the easiest method.

1.  In the RPI Imager, after selecting your OS, click **"Edit Settings"**.
2.  On the **General** tab, set a unique hostname for the Pi.
3.  On the **Services** tab, **Enable SSH** and select "Allow public-key authentication only".
4.  Paste the contents of your public key into the "Authorized public key" field. You can get this by running:
    ```bash
    cat ~/.ssh/pi_cluster_key.pub
    ```
5.  Save the settings and write the image to your SD card.

### \#\#\# Method B: For an Already Running Pi

The `ssh-copy-id` command is the standard way to add your key to a running server.

```bash
# Replace the user and IP address as needed
ssh-copy-id -i ~/.ssh/pi_cluster_key.pub your_user@192.168.1.101
```

## \#\# 3. Configuring Your SSH Client (`config` file)

The SSH `config` file is essential for creating aliases, especially when `.local` hostnames are not available (e.g., over a UniFi SD-WAN).

Open or create the file `~/.ssh/config` and add an entry for each Pi.

```ssh Config
# --- Pi Cluster ---
Host pi-node-1
  HostName      192.168.1.101
  User          your_pi_username
  IdentityFile  ~/.ssh/pi_cluster_key

Host pi-node-2
  HostName      192.168.1.102
  User          your_pi_username
  IdentityFile  ~/.ssh/pi_cluster_key

# Add entries for pi-node-3, pi-node-4, etc.
```

  * **`Host`**: The shortcut you will type (e.g., `ssh pi-node-1`).
  * **`HostName`**: The Pi's actual IP address.
  * **`User`**: The username on the Pi.
  * **`IdentityFile`**: **Crucially**, this tells SSH to use your specific private key for this connection.

Now, you can connect to any node using its simple alias.
