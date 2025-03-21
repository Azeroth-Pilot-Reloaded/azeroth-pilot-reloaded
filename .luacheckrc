---@diagnostic disable: lowercase-global
std = "lua51"
max_line_length = false
exclude_files = {
    ".github/",
    ".vscode/",
    "**/libs/**/*.lua",
    ".luacheckrc",
    "**/locales/*.lua",
    "**/.luarocks/**/", -- Created by the GitHub Action
    "**/.install/**/",  -- Created by the GitHub Action
}
ignore = {
    "1..", -- Everything related to globals
    "211", -- Unused local variable
    "212", -- Unused argument
    "43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
    "542", -- An empty if branch
}
