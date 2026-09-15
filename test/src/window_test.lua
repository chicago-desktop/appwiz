-- Add/Remove Programs' window: the registry entry the Start menu reads (the
-- Settings folder, windows.admin, the shell's picture), the permissions its
-- process carries, the process itself in a harness that names no
-- declarations folder, and a shot (test/shots/appwiz.png) drawn by the
-- shell's own renderer.
local test = require("test")
local registry = require("registry")
local gfx = require("gfx")
local fs = require("fs")
local app = require("app")
local ui = require("ui")
local render = require("render")
local rasters = require("rasters")
local images = require("images")
local window = require("window")

local definition = window.definition

-- The entry is 76x22 outside; the client is that minus the frame. The cell is
-- the stand's, where the shot was looked at.
local CLIENT = {w = 74, h = 19}
local CELL = {w = 10, h = 20}

local function data_of(id: string): (any, any)
    local entry: any = assert(registry.get(id))
    local data: any = type(entry.data) == "table" and entry.data or entry
    local meta: any = type(entry.meta) == "table" and entry.meta or {}
    return data, meta
end

local function open(): (any, any)
    local context = app.context({width = CLIENT.w, height = CLIENT.h, native = true,
        cell_w = CELL.w, cell_h = CELL.h})
    return definition.init(nil, context), context
end

-- Every node of a tree with an `id`, by id.
local function nodes(tree: any, out: any?): any
    local found: any = out or {}
    if type(tree) ~= "table" then return found end
    if tree.id then found[tree.id] = tree end
    for _, item in ipairs(tree.children or {}) do nodes(item, found) end
    return found
end

local function status_of(tree: any): string
    return tostring(tree.children[#tree.children].text)
end

local function face_font(): any
    local files = assert(fs.get("app:system_fonts"))
    return assert(gfx.font(assert(files:readfile("LiberationSans-Regular.ttf")), {size = 13, smooth = true}))
end

local function define_tests()
    test.describe("Add/Remove Programs window", function()
        test.it("is a Settings window on the shell SDK, for windows.admin only, with the shell's picture", function()
            local _, meta = data_of("windows.appwiz:window")
            test.eq(table.concat({meta.type, meta.title, meta.group, meta.image, meta.window_type,
                meta.pixel_render, meta.pixel_state}, "|"),
                "tui_desktop.window|Add/Remove Programs|Settings|appwizard|app|"
                    .. "windows.shell.sdk:render|windows.appwiz:window")
            -- An entry without the field opens for everyone, silently: the
            -- compositor asks the logged-on person's scope only when it is named.
            test.eq(meta.requires, "windows.admin")
            for _, size in ipairs({32, 16}) do
                local picture, why = images.get("appwizard", size)
                test.not_nil(picture, "appwizard@" .. tostring(size) .. ": " .. tostring(why))
            end
        end)

        test.it("carries its own two policies: no spawning, no registry changes, one environment variable", function()
            local data = data_of("windows.appwiz:window")
            local security: any = data.security or {}
            test.eq(table.concat(security.policies or {}, ","), "windows.appwiz:window_scope,windows.appwiz:window_env")
            local scope = data_of("windows.appwiz:window_scope")
            local actions: any = {}
            for _, action in ipairs(scope.policy.actions) do actions[action] = true end
            test.is_true(actions["hub.cache.list"] and actions["registry.find"] and actions["fs.get"] or false,
                "reads the cache, the declarations and the folder")
            for _, forbidden in ipairs({"process.spawn", "registry.apply", "exec.run", "env.get"}) do
                test.is_nil(actions[forbidden], forbidden .. " is not the scope's")
            end
            local env = data_of("windows.appwiz:window_env")
            test.eq(table.concat(env.policy.actions, ",") .. "|" .. table.concat(env.policy.resources, ","),
                "env.get|WINDOWS_DEPS_FS", "the environment by name, not *")
        end)

        test.it("without a declarations folder lists the modules read-only and says why", function()
            local state, context = open()
            test.is_true(state.readonly, "the harness names no WINDOWS_DEPS_FS")
            local shell: any = nil
            for _, line in ipairs(state.rows) do
                if line.component == "windows/shell" then shell = line end
            end
            test.not_nil(shell, "windows/shell is among the modules")
            test.eq(shell and shell.owner, "module", "declared by a module, not by the application")
            local tree = definition.view(state, context)
            local found = nodes(tree)
            test.is_true(found.install.disabled == true, "nothing to install into")
            test.is_true(found.remove.disabled == true, "nothing to remove from")
            -- Not set, rather than refused: the window's env policy grants the
            -- name, and a refusal would read "no env.get permission".
            test.eq(status_of(tree),
                "read-only: WINDOWS_DEPS_FS is not set — the application did not name the declarations folder")
            definition.update(state, {type = "activate", id = "close"}, context)
            test.is_true(context.closing, "Close closes the window")
        end)

        test.it("draws the panel into test/shots/appwiz.png", function()
            local state, context = open()
            local tree = definition.view(state, context)
            test.is_nil(ui.problem(tree))
            local store = rasters.store()
            store.begin()
            local placed = assert(render.placement({id = "appwiz", state_revision = 1, content_state = {sdk = 1, revision = 1,
                ui = tree, interaction = context.interaction}}, {x = 1, y = 1, cols = context.width, rows = context.height},
                CELL, {face = face_font()}, store))
            assert(assert(fs.get("app:shots")):writefile("appwiz.png", assert(placed.raster:encode("png"))))
            test.eq(placed.cols .. "x" .. placed.rows, tostring(context.width) .. "x" .. tostring(context.height))
        end)
    end)
end

local run_cases = test.run_cases(define_tests)
return {run = function(options) return run_cases(options) end}
