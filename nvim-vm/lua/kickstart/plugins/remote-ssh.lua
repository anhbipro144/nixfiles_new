return {
  "nosduco/remote-sshfs.nvim",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  opts = {
    -- Refer to the configuration section below
    connections = {
      -- Let the plugin read your personal SSH aliases (optional, for :RemoteSSHFSConnect my-ec2)
      ssh_configs = { vim.fn.expand("~/.ssh/config") },

      -- Force sshfs to use *this* key and skip /etc/ssh/ssh_config:
      sshfs_args = {
        "-o reconnect",
        "-o ConnectTimeout=5",
        "-o StrictHostKeyChecking=accept-new",
        "-o UserKnownHostsFile=" .. vim.fn.expand("~/.ssh/known_hosts"),
        "-o IdentityFile=" .. vim.fn.expand("~/.ssh/neo_ubuntu.pem"),
        "-o ssh_command=ssh -F none -o IdentitiesOnly=yes",
      },
    },
  },
}
