
--[[

  Nether mod for minetest

  Copyright (C) 2013 PilzAdam

  Permission to use, copy, modify, and/or distribute this software for
  any purpose with or without fee is hereby granted, provided that the
  above copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
  WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR
  BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
  OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
  SOFTWARE.

]]--


-- Functions

local function build_portal(pos, target)
	local p1 = {x = pos.x - 1, y = pos.y - 1, z = pos.z}
	local p2 = {x = p1.x + 3, y = p1.y + 4, z = p1.z}

	local path = minetest.get_modpath("nether") .. "/schematics/nether_portal.mts"
	minetest.place_schematic({x = p1.x, y = p1.y, z = p1.z - 2}, path, 0, nil, true)

	for y = p1.y, p2.y do
	for x = p1.x, p2.x do
		local meta = minetest.get_meta({x = x, y = y, z = p1.z})
		meta:set_string("p1", minetest.pos_to_string(p1))
		meta:set_string("p2", minetest.pos_to_string(p2))
		meta:set_string("target", minetest.pos_to_string(target))
	end
	end
end

local function move_check(p1, max, dir)
	local p = {x = p1.x, y = p1.y, z = p1.z}
	local d = math.abs(max - p1[dir]) / (max - p1[dir])

	while p[dir] ~= max do
		p[dir] = p[dir] + d
		if minetest.get_node(p).name ~= "default:obsidian" then
			return false
		end
	end

	return true
end


local function check_portal(p1, p2)
	if p1.x ~= p2.x then
		if not move_check(p1, p2.x, "x") then
			return false
		end
		if not move_check(p2, p1.x, "x") then
			return false
		end
	elseif p1.z ~= p2.z then
		if not move_check(p1, p2.z, "z") then
			return false
		end
		if not move_check(p2, p1.z, "z") then
			return false
		end
	else
		return false
	end

	if not move_check(p1, p2.y, "y") then
		return false
	end
	if not move_check(p2, p1.y, "y") then
		return false
	end

	return true
end


local function is_portal(pos)
	for d = -3, 3 do
		for y = -4, 4 do
			local px = {x = pos.x + d, y = pos.y + y, z = pos.z}
			local pz = {x = pos.x, y = pos.y + y, z = pos.z + d}

			if check_portal(px, {x = px.x + 3, y = px.y + 4, z = px.z}) then
				return px, {x = px.x + 3, y = px.y + 4, z = px.z}
			end
			if check_portal(pz, {x = pz.x, y = pz.y + 4, z = pz.z + 3}) then
				return pz, {x = pz.x, y = pz.y + 4, z = pz.z + 3}
			end
		end
	end
end


local function make_portal(pos)
	local p1, p2 = is_portal(pos)
	if not p1 or not p2 then
		return false
	end

	for d = 1, 2 do
	for y = p1.y + 1, p2.y - 1 do
		local p
		if p1.z == p2.z then
			p = {x = p1.x + d, y = y, z = p1.z}
		else
			p = {x = p1.x, y = y, z = p1.z + d}
		end
		if minetest.get_node(p).name ~= "air" then
			return false
		end
	end
	end

	local param2
	if p1.z == p2.z then
		param2 = 0
	else
		param2 = 1
	end

	local target = {x = p1.x, y = p1.y, z = p1.z}
	-- don't find nether, since nether-blocks not nether mod

	for d = 0, 3 do
	for y = p1.y, p2.y do
		local p
		if param2 == 0 then
			p = {x = p1.x + d, y = y, z = p1.z}
		else
			p = {x = p1.x, y = y, z = p1.z + d}
		end
		if minetest.get_node(p).name == "air" then
			minetest.set_node(p, {name = "nether:portal", param2 = param2})
		end
		local meta = minetest.get_meta(p)
		meta:set_string("p1", minetest.pos_to_string(p1))
		meta:set_string("p2", minetest.pos_to_string(p2))
		meta:set_string("target", minetest.pos_to_string(target))
	end
	end

	return true
end


-- ABMs

minetest.register_abm({
	nodenames = {"nether:portal"},
	interval = 1,
	chance = 2,
	action = function(pos, node)
		minetest.add_particlespawner({
			32, --amount
			4, --time
			{x = pos.x - 0.25, y = pos.y - 0.25, z = pos.z - 0.25}, --minpos
			{x = pos.x + 0.25, y = pos.y + 0.25, z = pos.z + 0.25}, --maxpos
			{x = -0.8, y = -0.8, z = -0.8}, --minvel
			{x = 0.8, y = 0.8, z = 0.8}, --maxvel
			{x = 0, y = 0, z = 0}, --minacc
			{x = 0, y = 0, z = 0}, --maxacc
			0.5, --minexptime
			1, --maxexptime
			1, --minsize
			2, --maxsize
			false, --collisiondetection
			"nether_particle.png" --texture
		})
	end,
})


-- Nodes

minetest.register_node("nether:portal", {
	description = "Nether Portal",
	tiles = {
		"nether_transparent.png",
		"nether_transparent.png",
		"nether_transparent.png",
		"nether_transparent.png",
		{
			name = "nether_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
		{
			name = "nether_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.5,
			},
		},
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	diggable = false,
	pointable = false,
	buildable_to = false,
	is_ground_content = false,
	drop = "",
	light_source = 5,
	post_effect_color = {a = 180, r = 128, g = 0, b = 128},
	alpha = 192,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.1,  0.5, 0.5, 0.1},
		},
	},
	groups = {not_in_creative_inventory = 1}
})

minetest.register_node(":default:obsidian", {
	description = "Obsidian",
	tiles = {"default_obsidian.png"},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 2},

	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local p1 = minetest.string_to_pos(meta:get_string("p1"))
		local p2 = minetest.string_to_pos(meta:get_string("p2"))
		local target = minetest.string_to_pos(meta:get_string("target"))
		if not p1 or not p2 then
			return
		end

		for x = p1.x, p2.x do
		for y = p1.y, p2.y do
		for z = p1.z, p2.z do
			local nn = minetest.get_node({x = x, y = y, z = z}).name
			if nn == "default:obsidian" or nn == "nether:portal" then
				if nn == "nether:portal" then
					minetest.remove_node({x = x, y = y, z = z})
				end
				local m = minetest.get_meta({x = x, y = y, z = z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end

		meta = minetest.get_meta(target)
		if not meta then
			return
		end
		p1 = minetest.string_to_pos(meta:get_string("p1"))
		p2 = minetest.string_to_pos(meta:get_string("p2"))
		if not p1 or not p2 then
			return
		end

		for x = p1.x, p2.x do
		for y = p1.y, p2.y do
		for z = p1.z, p2.z do
			local nn = minetest.get_node({x = x, y = y, z = z}).name
			if nn == "default:obsidian" or nn == "nether:portal" then
				if nn == "nether:portal" then
					minetest.remove_node({x = x, y = y, z = z})
				end
				local m = minetest.get_meta({x = x, y = y, z = z})
				m:set_string("p1", "")
				m:set_string("p2", "")
				m:set_string("target", "")
			end
		end
		end
		end
	end,
})

minetest.register_node("nether:rack", {
	description = "Netherrack",
	tiles = {"nether_rack.png"},
	is_ground_content = true,
	groups = {cracky = 3, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("nether:sand", {
	description = "Nethersand",
	tiles = {"nether_sand.png"},
	is_ground_content = true,
	groups = {crumbly = 3, level = 2, falling_node = 1},
	sounds = default.node_sound_gravel_defaults({
		footstep = {name = "default_gravel_footstep", gain = 0.45},
	}),
})

minetest.register_node("nether:glowstone", {
	description = "Glowstone",
	tiles = {"nether_glowstone.png"},
	is_ground_content = true,
	light_source = 14,
	paramtype = "light",
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("nether:brick", {
	description = "Nether Brick",
	tiles = {"nether_brick.png"},
	is_ground_content = false,
	groups = {cracky = 2, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

local fence_texture =
	"default_fence_overlay.png^nether_brick.png^default_fence_overlay.png^[makealpha:255,126,126"

minetest.register_node("nether:fence_nether_brick", {
	description = "Nether Brick Fence",
	drawtype = "fencelike",
	tiles = {"nether_brick.png"},
	inventory_image = fence_texture,
	wield_image = fence_texture,
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
	groups = {cracky = 2, level = 2},
	sounds = default.node_sound_stone_defaults(),
})


-- Register stair and slab

stairs.register_stair_and_slab(
	"nether_brick",
	"nether:brick",
	{cracky = 2, level = 2},
	{"nether_brick.png"},
	"nether stair",
	"nether slab",
	default.node_sound_stone_defaults()
)

-- StairsPlus

if minetest.get_modpath("moreblocks") then
	stairsplus:register_all(
		"nether", "brick", "nether:brick", {
			description = "Nether Brick",
			groups = {cracky = 2, level = 2},
			tiles = {"nether_brick.png"},
			sounds = default.node_sound_stone_defaults(),
	})
end

stairs.register_stair_and_slab("brick", "nether:brick",
	{cracky=3, oddly_breakable_by_hand=1},
	{"nether_brick.png"},
	"nether stair",
	"nether slab",
	default.node_sound_stone_defaults())


-- Craftitems

minetest.override_item("default:mese_crystal_fragment", {
	on_place = function(stack, _, pt)
		if pt.under and minetest.get_node(pt.under).name == "default:obsidian" then
			local done = make_portal(pt.under)
			if done and not minetest.settings:get_bool("creative_mode") then
				stack:take_item()
			end
		end

		return stack
	end,
})

-- Crafting

minetest.register_craft({
	output = "nether:brick 4",
	recipe = {
		{"nether:rack", "nether:rack"},
		{"nether:rack", "nether:rack"},
	}
})

minetest.register_craft({
	output = "nether:fence_nether_brick 6",
	recipe = {
		{"nether:brick", "nether:brick", "nether:brick"},
		{"nether:brick", "nether:brick", "nether:brick"},
	},
})


-- Mapgen

-- Initialize noise object, localise noise and data buffers

local nobj_cave = nil
local nbuf_cave = nil
local dbuf = nil


-- Content ids

local c_air = minetest.get_content_id("air")

--local c_stone_with_coal = minetest.get_content_id("default:stone_with_coal")
--local c_stone_with_iron = minetest.get_content_id("default:stone_with_iron")
local c_stone_with_mese = minetest.get_content_id("default:stone_with_mese")
local c_stone_with_diamond = minetest.get_content_id("default:stone_with_diamond")
local c_stone_with_gold = minetest.get_content_id("default:stone_with_gold")
--local c_stone_with_copper = minetest.get_content_id("default:stone_with_copper")
local c_mese = minetest.get_content_id("default:mese")

local c_gravel = minetest.get_content_id("default:gravel")
local c_dirt = minetest.get_content_id("default:dirt")
local c_sand = minetest.get_content_id("default:sand")

local c_cobble = minetest.get_content_id("default:cobble")
local c_mossycobble = minetest.get_content_id("default:mossycobble")
local c_stair_cobble = minetest.get_content_id("stairs:stair_cobble")

local c_lava_source = minetest.get_content_id("default:lava_source")
local c_lava_flowing = minetest.get_content_id("default:lava_flowing")
local c_water_source = minetest.get_content_id("default:water_source")
local c_water_flowing = minetest.get_content_id("default:water_flowing")

local c_glowstone = minetest.get_content_id("nether:glowstone")
local c_nethersand = minetest.get_content_id("nether:sand")
local c_netherbrick = minetest.get_content_id("nether:brick")
local c_netherrack = minetest.get_content_id("nether:rack")

