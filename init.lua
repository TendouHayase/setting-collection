-- [수정 1] local 오타 복구
local is_vscode = vim.g.vscode ~= nil
local is_windows = vim.fn.has("win32") == 1

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 들여쓰기
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.smartindent = true

-- 검색
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true

-- 화면
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.signcolumn = "yes"      -- 진단 표시 시 화면 밀림 방지
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.cursorline = true
vim.o.wrap = false
vim.o.confirm = true

-- Windows에서 파일 인코딩 문제 방지
vim.o.fileencodings = "utf-8,cp949,latin1"

-- 야드(yank) 하이라이트
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("UserYank", { clear = true }),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

if not is_vscode then
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.termguicolors = true
  vim.o.guifont = "JetBrainsMono Nerd Font:h10"

  vim.o.scrolloff = 8
  vim.o.sidescrolloff = 8
  vim.o.signcolumn = "yes"
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.cursorline = true
  vim.o.wrap = false
  vim.o.confirm = true
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
  -- ===== UI =====
  {
    -- [수정 10] config 내 colorscheme 제거, 옵션을 opts로 통합
    "folke/tokyonight.nvim",
    priority = 1000,
    cond = not is_vscode,
    opts = {
      style = "night",
      transparent = true,
      on_highlights = function(hl, c)
        hl.LspInlayHint = { bg = "none", fg = c.comment, italic = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    -- [수정 10] 테마 불일치 해소, setup 중복 제거
    "nvim-lualine/lualine.nvim",
    cond = not is_vscode,
    opts = { options = { theme = "tokyonight" } },
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
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "rics-dev/project-explorer.nvim",
    cond = not is_vscode,
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      -- [수정 14] 하드코딩 경로 제거
      paths = { vim.fn.expand("~/dev") .. "/*" },
      command_pattern = "fd . %s -td --min-depth %d --max-depth %d",
      newprojectpath = vim.fn.expand("~/dev") .. "/",
    },
    config = function(_, opts)
      require("project_explorer").setup(opts)
    end,
    -- [수정 12] lazy = false 제거, keys 지연 로딩만 유지
    keys = {
      { "<leader>fp", "<cmd>ProjectExplorer<cr>", desc = "Project Explorer" },
    },
  },

 {
  "nvim-treesitter/nvim-treesitter",
  cond = not is_vscode,
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({})

    local ensure_installed = {
      "c", "cpp", "rust", "lua", "toml", "vim", "vimdoc", "query", "markdown",
    }
    local installed = require("nvim-treesitter.config").get_installed()
    local to_install = vim.iter(ensure_installed)
      :filter(function(p) return not vim.tbl_contains(installed, p) end)
      :totable()
    if #to_install > 0 then
      require("nvim-treesitter").install(to_install)
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
      pattern = ensure_installed,
      callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
  },

  -- [수정 15] mason-org 조직으로 이관된 저장소 경로 사용
  { "mason-org/mason.nvim", cond = not is_vscode, config = true },
  {
    "mason-org/mason-lspconfig.nvim",
    cond = not is_vscode,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "clangd", "rust_analyzer", "taplo" },
      automatic_enable = true,
    },
  },
  { "neovim/nvim-lspconfig", cond = not is_vscode },

  -- [수정 3] cmp-buffer, cmp_luasnip 추가
  {
    "hrsh7th/nvim-cmp",
    cond = not is_vscode,
    event = "InsertEnter",
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
        -- [수정 3] 실제 설치된 소스만 지정
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
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
    end,
  },
  -- capabilities 생성을 위해 시작 시 로드. 모듈이 작아 비용은 미미함
  { "hrsh7th/cmp-nvim-lsp", cond = not is_vscode },
  { "hrsh7th/cmp-buffer", cond = not is_vscode, event = "InsertEnter" },
  { "saadparwaiz1/cmp_luasnip", cond = not is_vscode, event = "InsertEnter" },
  { "L3MON4D3/LuaSnip", cond = not is_vscode, event = "InsertEnter" },

  {
    "mfussenegger/nvim-dap",
    cond = not is_vscode,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Start/Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
      { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          -- [수정 6] Windows에서는 Mason shim이 .cmd 확장자를 가짐
          command = "codelldb" .. (is_windows and ".cmd" or ""),
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
      -- [수정 15] clangd를 쓰므로 C/C++ 설정도 추가
      dap.configurations.cpp = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },

  { "sevenc-nanashi/neov-ime.nvim", cond = not is_vscode },

  {
    -- [수정 7] VSCode 자체 자동 닫기와의 이중 동작 방지
    "windwp/nvim-autopairs",
    cond = not is_vscode,
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

-- ============ 순수 Neovim 전용 ============
if not is_vscode then
  -- [수정 5] 모든 autocmd에 augroup 지정하여 재소싱 시 중복 등록 방지
  local aug = vim.api.nvim_create_augroup("UserConfig", { clear = true })

  vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin"
    .. (is_windows and ";" or ":") .. vim.env.PATH

  -- [수정 4] cmp-nvim-lsp capabilities를 모든 서버에 전파
  vim.lsp.config("*", {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })

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
    group = aug,
    callback = function(ev)
      local opts = { buffer = ev.buf }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      end
    end,
  })

  if vim.g.neovide then
    vim.g.neovide_cursor_animation_length = 0.0
    vim.g.neovide_opacity = 0.75
  end

  -- [수정 14] 셸 설정을 Windows로 한정
  if is_windows then
    vim.opt.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = "\""
    vim.opt.shellxquote = ""
  end

  vim.o.mouse = "a"
  vim.o.mousemoveevent = true

  -- [수정 5] 진단/hover CursorHold 핸들러를 하나로 통합
  vim.api.nvim_create_autocmd("CursorHold", {
    group = aug,
    callback = function()
      if #vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 }) > 0 then
        vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
      else
        vim.lsp.buf.hover({ focus = false })
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      if vim.fn.bufname("%") == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
        require("persistence").stop()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = aug,
    nested = true,
    callback = function()
      if vim.fn.argc() == 0 then
        require("persistence").load()
      end
    end,
  })
end

-- ============ 공통 설정 ============
vim.o.updatetime = 300
vim.o.timeoutlen = 250

-- [수정 8] clipboard=unnamedplus로 이미 동작하므로 노멀 모드 <C-c>·<C-v> 매핑 제거.
--          비주얼 블록 진입은 <C-q>로 유지.
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true })
vim.keymap.set("i", "<C-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set("c", "<C-v>", "<C-r>+", { noremap = true, silent = true })

-- [수정 9] 인서트 모드 undo/redo는 <C-o>로 실행해 언두 블록 보존
vim.keymap.set("n", "<C-z>", "u", { noremap = true, silent = true })
vim.keymap.set("i", "<C-z>", "<C-o>u", { noremap = true, silent = true })
vim.keymap.set("n", "<C-S-z>", "<C-r>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-S-z>", "<C-o><C-r>", { noremap = true, silent = true })

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

  -- [수정 13] 포매팅 완료 콜백에서 저장을 호출해 경쟁 조건 제거
  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    vscode.action("editor.action.formatDocument", {
      callback = function()
        vscode.action("workbench.action.files.save")
      end,
    })
  end, { desc = "Format and Save (VSCode)" })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = vim.api.nvim_create_augroup("UserVSCode", { clear = true }),
    callback = function()
      vscode.action("editor.action.showHover")
    end,
  })
else
  vim.keymap.set("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
  vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Grep in Project" })
  vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "List Open Buffers" })

  vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
  vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close Buffer" })

  -- [수정 15] 인서트 모드에서는 먼저 빠져나온 뒤 포매팅해 커서 튐 방지
  vim.keymap.set("n", "<C-s>", function()
    vim.lsp.buf.format({ async = false })
    vim.cmd("write")
  end, { desc = "Format and Save" })
  vim.keymap.set("i", "<C-s>", "<Esc><cmd>lua vim.lsp.buf.format({ async = false }) vim.cmd('write')<cr>",
    { desc = "Format and Save" })
end
