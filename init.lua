--------------------------------------------------------
-- Minetest :: Macro Crafting Manager v2.0 (macro)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2016-2018, Leslie E. Krause
--------------------------------------------------------

local macro_bits = { 3, 6, 4, 2, 7, 5, 4, 8, 3, 6, 4, 2, 6, 4, 6, 9 }	-- be sure to update corresponding bits entry if sets table is changed!
local macro_sets = { }

macro_sets[ 1 ] = { false, false, false, false, false, false, true, true, true }
macro_sets[ 2 ] = { false, false, false, true, true, true, true, true, true }
macro_sets[ 3 ] = { true, true, false, true, true, false, false, false, false }
macro_sets[ 4 ] = { false, true, false, false, false, false, false, true, false }
macro_sets[ 5 ] = { true, false, true, true, true, true, true, false, true }
macro_sets[ 6 ] = { true, false, true, false, true, false, true, false, true }
macro_sets[ 7 ] = { false, true, false, true, false, true, false, true, false }
macro_sets[ 8 ] = { true, true, true, true, false, true, true, true, true }
macro_sets[ 9 ] = { true, false, false, true, false, false, true, false, false }
macro_sets[ 10 ] = { true, true, false, true, true, false, true, true, false }
macro_sets[ 11 ] = { true, false, true, true, false, true, false, false, false }
macro_sets[ 12 ] = { false, true, false, false, true, false, false, false, false }
macro_sets[ 13 ] = { true, false, true, true, false, true, true, false, true }
macro_sets[ 14 ] = { true, false, true, false, false, false, true, false, true }
macro_sets[ 15 ] = { true, false, false, true, true, false, true, true, true }
macro_sets[ 16 ] = { true, true, true, true, true, true, true, true, true }

local macro_formspec = "size[12,6.5]"
	.. default.gui_bg
	.. default.gui_bg_img
	.. default.gui_slots
--	.. "button[10,0;2,1;main;Purge All]"
	.. "button[8.2,2.5;0.8,1;move_extra;<<]"
--	.. "button[10.2,2.5;0.8,1;move_final;<<]"
	.. "button[8.2,4.7;0.8,1;move_craft;<<]"
	.. "list[current_player;craft;9,3.7;3,3;]"
	.. "label[9,2;Extra:]"
	.. "label[11,2;Result:]"
	.. "list[detached:%s_extra;main;9,2.5;1,1;]"
	.. "list[current_player;craftpreview;11,2.5;1,1;]"
	.. "listring[current_name;craft]"
	.. "listring[current_player;main]"

	.. "list[detached:trash;main;9,0;1,1;]"
	.. "image[9.1,0.1;0.8,0.8;creative_trash_icon.png]"
	.. "list[detached:macro;main;0,0;8,2;]"
	.. "image[0.1,0.1;0.8,0.8;creative_macro_icon1.png]"
	.. "image[1.1,0.1;0.8,0.8;creative_macro_icon2.png]"
	.. "image[2.1,0.1;0.8,0.8;creative_macro_icon3.png]"
	.. "image[3.1,0.1;0.8,0.8;creative_macro_icon4.png]"
	.. "image[4.1,0.1;0.8,0.8;creative_macro_icon5.png]"
	.. "image[5.1,0.1;0.8,0.8;creative_macro_icon6.png]"
	.. "image[6.1,0.1;0.8,0.8;creative_macro_icon7.png]"
	.. "image[7.1,0.1;0.8,0.8;creative_macro_icon8.png]"
	.. "image[0.1,1.1;0.8,0.8;creative_macro_icon9.png]"
	.. "image[1.1,1.1;0.8,0.8;creative_macro_icon10.png]"
	.. "image[2.1,1.1;0.8,0.8;creative_macro_icon11.png]"
	.. "image[3.1,1.1;0.8,0.8;creative_macro_icon12.png]"
	.. "image[4.1,1.1;0.8,0.8;creative_macro_icon13.png]"
	.. "image[5.1,1.1;0.8,0.8;creative_macro_icon14.png]"
	.. "image[6.1,1.1;0.8,0.8;creative_macro_icon15.png]"
	.. "image[7.1,1.1;0.8,0.8;creative_macro_icon16.png]"
	.. "list[current_player;main;0,2.5;8,1;]"
	.. "list[current_player;main;0,3.7;8,3;8]"
	.. default.get_hotbar_bg( 0, 2.5 )

----------------------
-- helper functions --
----------------------

default.get_contents = function ( chest_inv, player_inv, list )
	local slot, item
	for slot = 1, chest_inv:get_size( list or "main" ) do
		item = chest_inv:get_stack( list or "main", slot )
		if player_inv:room_for_item( "main", item ) then
			chest_inv:set_stack( list or "main", slot, nil )
			player_inv:add_item( "main", item )
		end
	end
end

default.put_contents = function ( chest_inv, player_inv, list )
	local slot, item
	for slot = 1, player_inv:get_size( "main" ) do
		item = player_inv:get_stack( "main", slot )
		if chest_inv:room_for_item( list or "main", item ) then
			player_inv:set_stack( "main", slot, nil )
			chest_inv:add_item( list or "main", item )
		end
	end
end

default.del_contents = function ( chest_inv, list )
	chest_inv:set_list( list or "main", { } )
end

default.drop_item = function ( pos, item, horz, vert )
        if not item.is_empty or not item:is_empty( ) then       -- confirm itemstring or a non-empty itemstack
                ( minetest.add_item( pos, item ) ):setvelocity( { x = math.random( -horz, horz ), y = vert, z = math.random( -horz, horz ) } )
        end
end

--------------------------
-- detached inventories --
--------------------------

local trash_inv = minetest.create_detached_inventory( "trash", {
	on_put = function( inv, toList, index, stack, player )
		inv:set_stack( "main", 1, nil )
	end
} )

local macro_inv = minetest.create_detached_inventory( "macro", {
	allow_put = function( inv, list, index, stack, player )
		local craft = player:get_inventory( ):get_list( "craft" )
		local extra = minetest.get_inventory( { type = "detached", name = player:get_player_name( ) .. "_extra" } )

		-- check that extra slot is empty
		if not extra:is_empty( "main" ) then
			return 0
		end

		-- check that all necessary craft slots are empty
		for i, v in ipairs( macro_sets[ index ] ) do
			if v == true and not craft[ i ]:is_empty( ) then
				return 0
			end
		end
		return -1
	end,
	on_put = function( inv, list, index, stack, player )
		local name = stack:get_name( )
		local count = stack:get_count( )

		local div_stack = ItemStack( { name = name, count = math.floor( count / macro_bits[ index ] ) } )
		local rem_stack = ItemStack( { name = name, count = count % macro_bits[ index ] } )
		local craft = player:get_inventory( ):get_list( "craft" )
		local extra = minetest.get_inventory( { type = "detached", name = player:get_player_name( ) .. "_extra" } )

		-- evenly divide stack into craft slots, with extra slot for remainder
		for i, v in ipairs( macro_sets[ index ] ) do
			if v == true then
				craft[ i ] = div_stack
			end
		end
		extra:set_stack( "main", 1, rem_stack )

		player:get_inventory( ):set_list( "craft", craft )
		inv:set_stack( "main", index, nil )
	end,
} )

trash_inv:set_size( "main", 1 )
macro_inv:set_size( "main", 16 )

--------------------------
-- registered callbacks --
--------------------------

local function on_macro_close( meta, player, fields )
        if fields.move_craft then
		default.get_contents( player:get_inventory( ), player:get_inventory( ), "craft" )
	elseif fields.move_extra then
		default.get_contents( meta.extra_inv, player:get_inventory( ) )
--	elseif fields.move_final then
--		default.get_contents( player:get_inventory( ), player:get_inventory( ), "craftpreview" )
	elseif fields.quit then
		default.drop_item( player:getpos( ), meta.extra_inv:get_stack( "main", 1 ), 0, 5 )
		meta.extra_inv:set_size( "main", 0 )
	end
end

minetest.register_on_joinplayer( function( player )
	local name = player:get_player_name( )

	minetest.create_detached_inventory( name .. "_extra", {
		allow_put = function( inv, list, index, stack, player )
			return 0
		end
	}, name )

	if minetest.get_modpath( "inventory_plus" ) then
		inventory_plus.register_button( player, "macro", "Macro" )
	end
end )

minetest.register_chatcommand( "x", {
	description = "Open the Macro Crafting Manager.",
	func = function( name, param )
		local extra_inv = minetest.get_inventory( { type = "detached", name = name .. "_extra" } )
		extra_inv:set_size( "main", 1 )
		minetest.create_form( { extra_inv = extra_inv }, name, string.format( macro_formspec, name ), on_macro_close )
	end,
} )

minetest.register_on_player_receive_fields( function( player, formname, fields )
        if minetest.get_modpath( "inventory_plus" ) and fields.macro then
		local name = player:get_player_name( )
		local extra_inv = minetest.get_inventory( { type = "detached", name = name .. "_extra" } )

		extra_inv:set_size( "main", 1 )
                minetest.create_form( { extra_inv = extra_inv }, player, string.format( macro_formspec, name ), on_macro_close )
	end
end )
