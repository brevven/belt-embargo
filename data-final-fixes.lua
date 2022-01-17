local util = require("data-util");
local butil = require("butil");
local futil = require("util");


-- determine which types of items to remove
local types =  {"transport-belt", "underground-belt", "splitter"}
if util.me.remove_loaders() then
  table.insert(types, "loader")
  table.insert(types, "loader-1x1")
end

-- build up a list of items to remove
for i, t in pairs(types) do
  if data.raw[t] then
    for j, entity in pairs(data.raw[t]) do
      butil.remove(entity.name, t)
    end
  end
end

-- handle miniloaders
if util.me.remove_loaders() and mods.miniloader then
  local miniloaders = {}
  for belt, t in pairs(butil.belts) do
    if belt:find("miniloader") then
      table.insert(miniloaders, belt)
    end
  end
  for i, belt in pairs(miniloaders) do
    belt = belt:gsub("%-loader", "")
    butil.remove(belt.."-inserter", "inserter")
    butil.remove(belt, "loader")
  end
end

-- remove KR void crushing recipes first
if mods.Krastorio2 then
  for belt in pairs(butil.belts) do
    util.remove_raw("recipe", "kr-vc-"..belt)
  end
end

-- replace belt ingredients, recursively
for i, recipe in pairs(data.raw.recipe) do
  if recipe then
    -- skip over belt recipes as we're not going to use them anyways
    if ((recipe.result and butil.belts[recipe.result]) or
       (recipe.results and #recipe.results == 1 and 
          (butil.belts[recipe.results[1][1]] or
          butil.belts[recipe.results[1].name]))) or
       ((recipe.normal and recipe.normal.result and butil.belts[recipe.normal.result]) or
       (recipe.normal and recipe.normal.results and #recipe.normal.results == 1 and 
          (butil.belts[recipe.normal.results[1][1]] or
          butil.belts[recipe.normal.results[1].name])))
      then
      goto continue
    end
    if recipe.ingredients then
      -- log("-----------------------")
      -- log("BZZZZ .." ..recipe.name)
      butil.replace_belts(recipe.ingredients)
      for i, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "fluid" and (recipe.category == "crafting" or recipe.category == nil) then
          recipe.category = "crafting-with-fluid"
        end
      end
      -- log("DONE ".. serpent.dump(recipe))
    elseif recipe.normal and recipe.normal.ingredients then
      -- log("-----------------------")
      -- log("BZZZZ ..".. recipe.name)
      butil.replace_belts(recipe.normal.ingredients)
      if recipe.expensive and recipe.expensive.ingredients then
        butil.replace_belts(recipe.expensive.ingredients)
      end
      for i, ingredient in pairs(recipe.normal.ingredients) do
        if ingredient.type == "fluid" and (recipe.category == "crafting" or recipe.category == nil) then
          recipe.category = "crafting-with-fluid"
        end
      end
      -- log("DONE ".. serpent.dump(recipe))
    end
  end
  ::continue::
end

-- replace belt products for multi-product recipes
-- TODO in future update -- will crash with multi-product recipes for now

-- remove belt recipes
local recipes =  {}
for i, recipe in pairs(data.raw.recipe) do
  if ((recipe.result and butil.belts[recipe.result]) or
     (recipe.results and #recipe.results == 1 and 
        (butil.belts[recipe.results[1][1]] or
        butil.belts[recipe.results[1].name]))) or
     ((recipe.normal and recipe.normal.result and butil.belts[recipe.normal.result]) or
     (recipe.normal and recipe.normal.results and #recipe.normal.results == 1 and 
        (butil.belts[recipe.normal.results[1][1]] or
        butil.belts[recipe.normal.results[1].name])))
    then
      log("Removing recipe "..recipe.name)
      recipes[recipe.name] = true
      util.remove_raw("recipe", recipe.name)
  end
end

-- remove belt items
for belt in pairs(butil.belts) do
  log("Removing item "..belt)
  util.remove_raw("item", belt)
end

-- make dummy entities due to factorio base requirements
for i, t in pairs(types) do 
  for belt, ty in pairs(butil.belts) do
    if t == ty then
      log("Making dummy of "..t.." - "..belt) 
      entity = futil.table.deepcopy(data.raw[t][belt])
      entity.minable = nil
      entity.placeable_by = nil
      entity.name = "dummy-"..t
      entity.next_upgrade = nil
      entity.related_underground_belt = nil
      data:extend({entity})
      break
    end
  end
end

-- remove belt entities
for belt, t in pairs(butil.belts) do
  log("Removing "..t.." "..belt)
  util.remove_raw(t, belt)
end

-- remove belt unlocks
for i, tech in pairs(data.raw.technology) do
  butil.remove_belt_unlocks(tech, recipes)
end


-- remove tips-and-tricks that use belts
util.remove_raw("tips-and-tricks-item", "transport-belts")
util.remove_raw("tips-and-tricks-item", "belt-lanes")
util.remove_raw("tips-and-tricks-item", "underground-belts")
util.remove_raw("tips-and-tricks-item", "splitters")
util.remove_raw("tips-and-tricks-item", "splitter-filters")
util.remove_raw("tips-and-tricks-item", "fast-replace")
util.remove_raw("tips-and-tricks-item", "fast-replace-belt-splitter")
util.remove_raw("tips-and-tricks-item", "fast-replace-belt-underground")
util.remove_raw("tips-and-tricks-item", "fast-replace-direction")
util.remove_raw("tips-and-tricks-item", "z-dropping")
util.remove_raw("tips-and-tricks-item", "drag-building-underground-belts")
util.remove_raw("tips-and-tricks-item", "fast-belt-bending")
util.remove_raw("tips-and-tricks-item", "fast-obstacle-traversing")


-- set up technologies to remove
-- some basic belt techs we know about
local techs = {
  "logistics",

  "basic-logistics", -- AAI

  "omt-logistics-4", -- one more tier

  "BetterBelts_ultra-class",
  "uranium-transport-belts",
}
-- "logistics-N" techs
for i=0,10,1 do
  table.insert(techs, "logistics-"..i)
end
for i, tech in pairs(techs) do
  butil.techs[tech] = true
end
-- in case any techs are named after belt entities
for belt, t in pairs(butil.belts) do
  butil.techs[belt] = true
end

--if util.me.remove_loaders() then
--
  
-- Make sure we don't remove techs if they still unlock things
for tech in pairs(butil.techs) do
  local technology = data.raw.technology[tech]
  if not (technology and (technology.effects == nil or #technology.effects == 0)) then
    butil.techs[tech] = nil
  end
end

-- Rework technology tree
for i, tech in pairs(data.raw.technology) do
  butil.remove_belt_prereqs(tech)
end

-- Finally, remove techs that are no longer needed
for tech in pairs(butil.techs) do
  local technology = data.raw.technology[tech]
  -- repeat cheap check above just in case
  if technology and (technology.effects == nil or #technology.effects == 0) then
    util.remove_raw("technology", tech)
  end
end


-- TODO make it work with WaterTurrets
