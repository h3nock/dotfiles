-- ~/.config/nvim/lua/plugins/competitest.lua
return {
  {
    "MunifTanjim/nui.nvim",
    lazy = false,
  },
  {
    "xeluxee/competitest.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("competitest").setup {

        runner_ui = {
          interface = "split",
        },

        split_ui = {
          total_width = 0.4,
        },
        -- ──────────────────────────────────────────────────────────────────────
        -- (A) Compile & Run Settings (unchanged)
        compile_command = {
          cpp = {
            exec = "/opt/homebrew/bin/g++-15",
            args = {
              "-std=c++17",
              "-O2",
              "-Wall",
              "-o",
              "$(FNOEXT).out",
              "$(FNAME)",
            },
          },
        },
        run_command = {
          cpp = { exec = "./$(FNOEXT).out" },
        },

        -- ──────────────────────────────────────────────────────────────────────
        -- (B) Competitive Companion Integration
        companion_port = 27121,
        receive_print_message = true,
        start_receiving_persistently_on_setup = false,

        -- ──────────────────────────────────────────────────────────────────────
        -- (C) Use your C++ starter template for every new problem
        template_file = "$(HOME)/cp/templates/template.cpp",

        -- ──────────────────────────────────────────────────────────────────────
        -- (D) “Practice” (single problem) layout with sanitized names
        received_problems_path = function(task, ext)
          -- Extract the judge from “group” (e.g. “Codeforces” from “Codeforces - …”)
          local judge = task.group:match "^([^%-]+)%s*%-" or task.group

          -- Sanitize the problem name (replace spaces & dots, strip other punctuation)
          local raw = task.name -- e.g. "G. Castle Defense"
          local sanitized = raw
            :gsub("%s+", "_") -- spaces → underscores
            :gsub("%.", "") -- dots → ""
            :gsub("[^%w_%-]", "") -- remove anything not alphanumeric, underscore, or hyphen

          -- Build and return the full filepath:
          return string.format(
            "%s/cp/%s/practice/%s/%s.%s",
            vim.loop.os_homedir(),
            judge:match "^%s*(.-)%s*$", -- trim whitespace
            sanitized,
            sanitized,
            ext
          )
        end,

        -- ──────────────────────────────────────────────────────────────────────
        -- (E) “Contest” layout with sanitized names
        received_contests_directory = "$(HOME)/cp/$(JUDGE)/contests",
        received_contests_problems_path = function(task, ext)
          local grp = task.group
          -- drop the leading "<platform> -" ex: "Codeforces - "
          grp = grp:gsub("^[^%-]+%-%s*", "")
          -- remove any "(...)"
          grp = grp:gsub("%s*%b()", "")
          -- abbreviate
          grp = grp:gsub("Educational", "Edu"):gsub("Codeforces", "CF")
          -- normalize whitespace and trim ends
          grp = grp:gsub("%s+", " "):match "^%s*(.-)%s*$"

          local folder = grp:gsub("%s+", "_"):gsub("#", ""):gsub("[^%w_%-]", "")

          -- Sanitize each problem name
          local raw = task.name -- e.g. "G. Castle Defense"
          local sanitized = raw:gsub("%s+", "_"):gsub("%.", ""):gsub("[^%w_%-]", "")

          -- Path relative to “<contests>/<ContestID>/”
          return string.format("%s/%s/%s.%s", folder, sanitized, sanitized, ext)
        end,

        -- ──────────────────────────────────────────────────────────────────────
        -- (F) Multiple‐text‐file testcase mode
        testcases_directory = ".",
        testcases_use_single_file = false,
        testcases_input_file_format = "input$(TCNUM).txt",
        testcases_output_file_format = "output$(TCNUM).txt",
      }
    end,
  },
}
