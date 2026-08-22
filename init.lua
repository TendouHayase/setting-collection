local is_vscode = vim.g.vscode ~= nil

-- 순수 Neovim(터미널/GUI)에서만 의미 있는 UI/폰트 설정
if not is_vscode then
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.termguicolors = true
  vim.o.guifont = "JetBrainsMono Nerd Font:h10"
end

vim.o.clipboard = "unnamedplus"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- ===== UI: VSCode가 자체 UI를 갖고 있으므로 전부 비활성화 =====
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    cond = not is_vscode,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  { "nvim-lualine/lualine.nvim", cond = not is_vscode, opts = {} },
  {
    "nvim-tree/nvim-tree.lua",
    cond = not is_vscode,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      renderer = {
        icons = {
          show = { file = true, folder = true, folder_arrow = true, git = true },
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    cond = not is_vscode,
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
  },
  {
    "vyfor/cord.nvim",
    cond = not is_vscode,
    event = "VeryLazy",
    opts = {
      editor = { client = "neovim", tooltip = "The Superior Text Editor" },
      display = { show_time = true, show_repository = true, show_cursor_position = true },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    cond = not is_vscode,
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "rics-dev/project-explorer.nvim",
    cond = not is_vscode,
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      paths = { "C:/Users/UshioHayase/dev/*" },
      command_pattern = "fd . %s -td --min-depth %d --max-depth %d",
      newprojectpath = "C:/Users/UshioHayase/dev/",
      file_explorer = function(dir)
        require("nvim-tree.api").tree.open(dir)
      end,
    },
    config = function(_, opts)
      require("project_explorer").setup(opts)
    end,
    keys = {
      { "<leader>fp", "<cmd>ProjectExplorer<cr>", desc = "Project Explorer" },
    },
    lazy = false,
  },

  { "nvim-treesitter/nvim-treesitter", cond = not is_vscode, build = ":TSUpdate" },

  { "williamboman/mason.nvim", cond = not is_vscode, config = true },
  {
    "williamboman/mason-lspconfig.nvim",
    cond = not is_vscode,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "clangd", "rust_analyzer", "taplo" },
      automatic_enable = true,
    },
  },
  { "neovim/nvim-lspconfig", cond = not is_vscode },
  { "hrsh7th/nvim-cmp", cond = not is_vscode },
  { "hrsh7th/cmp-nvim-lsp", cond = not is_vscode },
  { "L3MON4D3/LuaSnip", cond = not is_vscode },

  {
    "mfussenegger/nvim-dap",
    cond = not is_vscode,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
    end,
  },

  { "sevenc-nanashi/neov-ime.nvim", cond = not is_vscode },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  {
    "folke/trouble.nvim",
    cond = not is_vscode,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
    opts = {},
  },

  {
    "folke/persistence.nvim",
    cond = not is_vscode,
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
})

-- ============ 순수 Neovim에서만 실행되는 블록 ============
if not is_vscode then
  local is_windows = vim.fn.has("win32") == 1
  vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin"
    .. (is_windows and ";" or ":") .. vim.env.PATH

  vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy" },
  })

  vim.lsp.config("rust_analyzer", {
    settings = {
      ["rust-analyzer"] = {
        cargo = { features = "all" },
        checkOnSave = true,
        check = { command = "clippy" },
      },
    },
  })

  vim.lsp.config("taplo", {})

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      local opts = { buffer = ev.buf }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end,
  })

  local cmp = require("cmp")
  cmp.setup({
    snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
    sources = { { name = "nvim_lsp" }, { name = "buffer" } },
    mapping = cmp.mapping.preset.insert({
      ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.confirm({ select = true }) else fallback() end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item() else fallback() end
      end, { "i", "s" }),
    }),
  })

  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

  local dap = require("dap")
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
      args = { "--port", "${port}" },
    },
  }
  dap.configurations.rust = {
    {
      name = "Launch",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }

  require("lualine").setup({ options = { theme = "onedark" } })

  require("tokyonight").setup({
    style = "night",
    transparent = true,
    on_highlights = function(hl, c)
      hl.NvimTreeNormal = { bg = "none" }
      hl.NvimTreeNormalNC = { bg = "none" }
      hl.NvimTreeEndOfBuffer = { bg = "none" }
      hl.NeoTreeNormal = { bg = "none" }
      hl.NeoTreeNormalNC = { bg = "none" }
      hl.NeoTreeEndOfBuffer = { bg = "none" }
      hl.LspInlayHint = { bg = "none", fg = c.comment, italic = true }
    end,
  })
  vim.cmd.colorscheme("tokyonight")

  if vim.g.neovide then
    vim.g.neovide_cursor_animation_length = 0.0
    vim.g.neovide_opacity = 0.75
  end

  vim.opt.shell = "powershell"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = "\""
  vim.opt.shellxquote = ""

  vim.o.mouse = "a"
  vim.o.mousemoveevent = true

  -- 진단(diagnostic) 플로팅 창
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
      vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
    end,
  })

  -- 커서가 멈추면 자동으로 hover 표시
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
      vim.lsp.buf.hover()
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if vim.fn.bufname("%") == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
        require("persistence").stop()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    nested = true,
    callback = function()
      if vim.fn.argc() == 0 then
        require("persistence").load()
      end
    end,
  })
end

-- ============ 두 환경 모두에서 동작하는 공통 설정 ============
vim.o.updatetime = 300
vim.o.timeoutlen = 250
vim.keymap.set({ "n", "v" }, "<C-c>", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "<C-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("v", "<C-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("i", "<C-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set("c", "<C-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set({ "n", "i", "v" }, "<C-z>", "<cmd>undo<cr>", { desc = "Undo" })
vim.keymap.set({ "n", "i", "v" }, "<C-S-z>", "<cmd>redo<cr>", { desc = "Redo" })

vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

if is_vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "<leader>e", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
  end, { desc = "Toggle Sidebar" })

  vim.keymap.set("n", "<leader>ff", function()
    vscode.action("workbench.action.quickOpen")
  end, { desc = "Find Files (VSCode)" })

  vim.keymap.set("n", "<leader>fg", function()
    vscode.action("workbench.action.findInFiles")
  end, { desc = "Grep in Project (VSCode)" })

  vim.keymap.set("n", "<leader>fb", function()
    vscode.action("workbench.action.showAllEditors")
  end, { desc = "List Open Editors (VSCode)" })

  vim.keymap.set("n", "<leader>de", function()
    vscode.action("editor.action.marker.next")
  end, { desc = "Show Line Diagnostics (VSCode)" })

  vim.keymap.set("n", "<S-l>", function()
    vscode.action("workbench.action.nextEditor")
  end, { desc = "Next Editor" })

  vim.keymap.set("n", "<S-h>", function()
    vscode.action("workbench.action.previousEditor")
  end, { desc = "Previous Editor" })

  vim.keymap.set("n", "<leader>bd", function()
    vscode.action("workbench.action.closeActiveEditor")
  end, { desc = "Close Editor" })

  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    vscode.action("editor.action.formatDocument")
    vscode.action("workbench.action.files.save")
  end, { desc = "Format and Save (VSCode)" })

  -- 커서가 멈추면 자동으로 hover 표시
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
      vscode.action("editor.action.showHover")
    end,
  })
else
  vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle File Tree" })
  vim.keymap.set("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
  vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Grep in Project" })
  vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "List Open Buffers" })

  vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
  vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close Buffer" })

  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    vim.lsp.buf.format({ async = false })
    vim.cmd("write")
  end, { desc = "Format and Save" })
end