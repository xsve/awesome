--opening gconf-editor and editing
--this key:
--/desktop/gnome/session/required_components_list
--and removing "panel". Log out/back in and no pane

-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
require("awful.titlebar")
require("awesome")
require("client")
require("screen")
require("freedesktop.utils")
require("freedesktop.menu")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "gnome-terminal"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

--{{{ Run or raise
--- Spawns cmd if no client can be found matching properties
-- If such a client can be found, pop to first tag where it is visible, and give it focus
-- @param cmd the command to execute
-- @param properties a table of properties to match against clients.  Possible entries: any properties of the client object
function run_or_raise(cmd, properties)
    local clients = client.get()
    local focused = awful.client.next(0)
    local findex = 0
    local matched_clients = {}
    local n = 0

    -- Returns true if all pairs in table1 are present in table2
    function match (table1, table2)
        for k, v in pairs(table1) do
            if table2[k] ~= v and not table2[k]:find(v) then
                return false
            end
        end
        return true
    end

    for i, c in pairs(clients) do
        --make an array of matched clients
        if match(properties, c) then
            n = n + 1
            matched_clients[n] = c
            if c == focused then
                findex = n
            end
        end
    end
    if n > 0 then
        local c = matched_clients[1]
        -- if the focused window matched switch focus to next in list
        if 0 < findex and findex < n then
            c = matched_clients[findex+1]
        end
        local ctags = c:tags()
        if table.getn(ctags) == 0 then
            -- ctags is empty, show client on current tag
            local curtag = awful.tag.selected()
            awful.client.movetotag(curtag, c)
        else
            -- Otherwise, pop to first tag client is visible on
            awful.tag.viewonly(ctags[1])
        end
        -- And then focus the client
        if client.focus == c then
            c:tags({})
        else
            client.focus = c
            c:raise()
        end
        return
    end
    awful.util.spawn(cmd, false)
end
--}}}


--{{{ Data serialisation helpers
function client_name(c)
    local cls = c.class or ""
    local inst = c.instance or ""
	local role = c.role or ""
	local ctype = c.type or ""
	return cls..":"..inst..":"..role..":"..ctype
end

-- where can be 'left' 'right' 'center' nil
function client_snap(c, where, geom)
    local sg = screen[c.screen].geometry
    local cg = geom or c:geometry()
    local cs = c:struts()
    cs['left'] = 0
    cs['top'] = 0
    cs['bottom'] = 0
    cs['right'] = 0
    if where == 'right' then
        cg.x = sg.width - cg.width
        cs[where] = cg.width
        c:struts(cs)
        c:geometry(cg)
    elseif where == 'left' then
        cg.x = 0
        cs[where] = cg.width
        c:struts(cs)
        c:geometry(cg)
    elseif where == 'bottom' then
        awful.placement.centered(c)
        cg = c:geometry()
        cg.y = sg.height - cg.height - beautiful.wibox_bottom_height
        cs[where] = cg.height + beautiful.wibox_bottom_height
        c:struts(cs)
        c:geometry(cg)
    elseif where == nil then
        c:struts(cs)
        c:geometry(cg)
    elseif where == 'center' then
        c:struts(cs)
        awful.placement.centered(c)
    else
        return
    end
end

function save_geometry(c, g)
	myrc.memory.set("geometry", client_name(c), g)
    if g ~= nil then
        c:geometry(g)
    end
end

function save_floating(c, f)
	myrc.memory.set("floating", client_name(c), f)
    awful.client.floating.set(c, f)
end

function save_titlebar(c, val)
	myrc.memory.set("titlebar", client_name(c), val)
	if val == true then
		awful.titlebar.add(c, { modkey = modkey })
	elseif val == false then
		awful.titlebar.remove(c)
	end
	return val
end

function get_titlebar(c, def)
	return myrc.memory.get("titlebar", client_name(c), def)
end

function save_tag(c, tag)
	local tn = "none"
	if tag then tn = tag.name end
	myrc.memory.set("tags", client_name(c), tn)
	if tag ~= nil and tag ~= awful.tag.selected() then 
		awful.client.movetotag(tag, c) 
	end
end

function get_tag(c, def)
	local tn = myrc.memory.get("tags", client_name(c), def)
	return myrc.tagman.find(tn)
end

function save_dockable(c, val)
	myrc.memory.set("dockable", client_name(c), val)
    awful.client.dockable.set(c, val)
end

function get_dockable(c, def)
	return myrc.memory.get("dockable", client_name(c), def)
end

function save_hor(c, val)
	myrc.memory.set("maxhor", client_name(c), val)
    c.maximized_horizontal = val
end

function get_hor(c, def)
	return myrc.memory.get("maxhor", client_name(c), def)
end

function save_vert(c, val)
	myrc.memory.set("maxvert", client_name(c), val)
    c.maximized_vertical = val
end

function get_vert(c, def)
	return myrc.memory.get("maxvert", client_name(c), def)
end

function save_snap(c, val)
	myrc.memory.set("snap", client_name(c), val)
    client_snap(c, val)
end

function get_snap(c, def)
	return myrc.memory.get("snap", client_name(c), def)
end

function save_hidden(c, val)
	myrc.memory.set("hidden", client_name(c), val)
    c.skip_taskbar = val
end

function get_hidden(c, def)
	return myrc.memory.get("hidden", client_name(c), def)
end

function get_border(c, def)
	return myrc.memory.get("border", client_name(c), def)
end

function get_layout_border(c)
    if awful.client.floating.get(c) == false and 
        awful.layout.get() == awful.layout.suit.max
    then
        return 0
    else
        return get_border(c, beautiful.border_width)
    end
end

function save_border(c, val)
    myrc.memory.set("border", client_name(c), val)
    c.border_width = get_layout_border(c)
end
--}}}

-- Menu helpers--{{{
mymenu = nil
function menu_hide()
    if mymenu ~= nil then
        mymenu:hide()
        mymenu = nil
    end
end

function menu_current(menu, args)
    if mymenu ~= nil and mymenu ~= menu then
        mymenu:hide()
    end
    mymenu = menu
    mymenu:show(args)
    return mymenu
end

function client_contex_menu(c)
    local mp = mouse.coords()
    local menupos = {x = mp.x-1*beautiful.menu_width/3, y = mp.y}

    local menuitmes = {
        {"               ::: "..c.class.." :::" ,nil,nil}
        ,

        {"&Q Kill", function () 
            c:kill()
        end},

        {"",nil,nil}
        ,

        {"&F Floating", {
            { "&Enable", function () 
                save_floating(c, true)
            end},
            { "&Disable", function () 
                save_floating(c, false)
            end}
        }},

        {"&T Titlebar", {
            { "&Enable" , function () 
                save_titlebar(c, true)
            end},

            {"&Disable", function () 
                save_titlebar(c, false)
            end},
        }},

        {"&G Geometry", {
            { "&Save" , function () 
                save_geometry(c, c:geometry())
            end},

            {"&Clear", function () 
                save_geometry(c, nil)
            end},
        }},

        {"&V Fullscreen vert", {
            {"&Enable", function () 
                save_vert(c, true) 
            end},
            {"&Disable" , function () 
                save_vert(c, false) 
            end},
        }},

        {"&H Fullscreen hor", {
            {"&Enable", function () 
                save_hor(c, true) 
            end},
            {"&Disable" , function () 
                save_hor(c, false) 
            end},
        }},

        {"&S Snap", {
            { "&Center", function () 
                save_snap(c, 'center')
            end},

            {"&Right", function () 
                save_snap(c, 'right')
            end},

            {"&Left", function () 
                save_snap(c, 'left')
            end},

            {"&Bottom", function () 
                save_snap(c, 'bottom')
            end},

            {"&Off", function () 
                save_snap(c, nil)
            end},
        }},

        {"&B Border", {
            { "&None", function () 
                save_border(c, 0)
            end},

            {"&One", function () 
                save_border(c, 1)
            end},

            {"&Default", function () 
                save_border(c, nil)
            end},
        }},

        {"&S Stick", {
            { "To &this tag", 
            function () 
                local t = awful.tag.selected()
                save_tag(c, t) 
                naughty.notify({text = "Client " .. c.name .. " has been sticked to tag " .. t.name}) 
            end}, 

            {"To &none", function () 
                save_tag(c, nil) 
                naughty.notify({text = "Client " .. c.name .. " has been unsticked from tag"}) 
            end},
        }},

        { "&I Hidden", {
            {"&Enable", function () 
                save_hidden(c, true) 
            end},
            {"&Disable" , function () 
                save_hidden(c, false) 
            end},
        }},

        {"&R Rename", function () 
            awful.prompt.run(
            { prompt = "Rename client: " }, 
            mypromptbox[mouse.screen].widget, 
            function(n) 
                awful.client.property.set(c,"label", n) 
            end,
            awful.completion.bash,
            awful.util.getdir("cache") .. "/rename")
        end},
    } 

    return awful.menu( { items = menuitmes, height = theme.menu_context_height } ), menupos
end--}}}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,          --1
    awful.layout.suit.tile,              --2
    awful.layout.suit.tile.left,         --3
    awful.layout.suit.tile.bottom,       --4
    awful.layout.suit.tile.top,          --5
    awful.layout.suit.fair,              --6
    awful.layout.suit.fair.horizontal,   --7
    awful.layout.suit.spiral,            --8
    awful.layout.suit.spiral.dwindle,    --9
    awful.layout.suit.max,               --10
    awful.layout.suit.max.fullscreen,    --11
    awful.layout.suit.magnifier          --12
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
  names = { "www", "gedit", "IDE", "email", 
            "fs", "terms", "video", 
            "IM", "misc",
  },
  layout = {
    layouts[1], layouts[1], layouts[1], layouts[9],
    layouts[2], layouts[1], layouts[12],
    layouts[3], layouts[12],
}}
for s = 1, screen.count() do
    tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "GnoMenu", "GnoMenu.py run-in-tray"},
   { "GNOME Settings", "gnome-control-center" },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal },
                                    { "Thunderbird", "/opt/thunderbird/thunderbird" },
                                    { "EclipseRD", "/opt/eclipserd/eclipse/eclipse" },
                                    { "Dropbox", "/afs/ericpol.int/home/x/s/xsve/home/.dropbox-dist/dropboxd start"},
                                    { "Shutdown", "gnome-session-save --shutdown-dialog" }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mysystray,
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        --s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "Up",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "Down",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    --awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

--os.execute("gnome-settings-daemon")
-- }}}

