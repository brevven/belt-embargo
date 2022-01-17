local util = require("data-util");
local butil = require("butil");


local roots = {
  "transport-belt", "underground-belt", "splitter",
}
local loader_roots = {
    "loader",

    -- miniloader
    "miniloader", "filter-miniloader",

    -- deadlock loaders
    "transport-belt-loader",

    -- modmash
    "mini-loader",
}

if util.me.remove_loaders() then 
  for i, loader in pairs(loader_roots) do
    table.insert(roots, loader)
  end
end

local prefixes = {}
for i, entity in pairs(data.raw["transport-belt"]) do
  local name = entity.name
  name = string.gsub(name, "transport%-belt.*", "")
  log("Found transport belt prefix to remove: ".. name)
  table.insert(prefixes, name)
end

local suffixes = {}
suffixes["se-deep-space-"]={"", "-blue", "-cyan", "-green", "-magenta", "-red", "-yellow", "-white"}
suffixes["BetterBelts_ultra-"]={"", "-v1", "-v2", "-v3"}
suffixes["5d-"]={
  "-04", "-05", "-06", "-07", "-08", "-09", "-10",
  "-30-04", "-30-05", "-30-06", "-30-07", "-30-08", "-30-09", "-30-10",
  "-50-04", "-50-05", "-50-06", "-50-07", "-50-08", "-50-09", "-50-10",
}
if mods.modmashsplinterlogistics then
  suffixes["high-speed-"]={"", "-structure"}
  suffixes["regenerative-"]={"", "-structure"}
end


local techs = {
  "logistics", "logistics-2", "logistics-3",

  -- bob's
  "logistics-0", "logistics-1", "logistics-4", "logistics-5",

  -- one more tier
  "omt-logistics-4",

  "BetterBelts_ultra-class",
  "uranium-transport-belts",
}

if mods.miniloader and util.me.remove_loaders() then
  for i, prefix in pairs(prefixes) do
    table.insert(techs, prefix.."miniloader")
  end
end

for i, tech in pairs(techs) do
  butil.techs[tech] = true
end



for i, prefix in pairs(prefixes) do
  local mysuffixes = suffixes[prefix] and suffixes[prefix] or {""}
  for k, suffix in pairs(mysuffixes) do 
    for j, root in pairs(roots) do
      butil.belts[prefix..root..suffix] = true
    end
  end
end
butil.belts["chute-miniloader"] = true
butil.belts["space-miniloader"] = true
butil.belts["space-filter-miniloader"] = true
butil.belts["deep-space-miniloader"] = true
butil.belts["deep-space-filter-miniloader"] = true
butil.belts["kr-se-loader"] = true
butil.belts["kr-se-deep-space-loader-black"] = true

-- remove KR void crushing recipes first
if mods.Krastorio2 then
  for belt in pairs(butil.belts) do
    util.remove_raw("recipe", "kr-vc-"..belt)
  end
end

-- replace belt ingredients
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
    log("---------------------------")
    log(recipe.name)
    if recipe.ingredients then
      butil.replace_belts(recipe.ingredients)
      for i, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "fluid" and (recipe.category == "crafting" or recipe.category == nil) then
          recipe.category = "crafting-with-fluid"
        end
      end
    elseif recipe.normal and recipe.normal.ingredients then
      butil.replace_belts(recipe.normal.ingredients)
      for i, ingredient in pairs(recipe.normal.ingredients) do
        if ingredient.type == "fluid" and (recipe.category == "crafting" or recipe.category == nil) then
          recipe.category = "crafting-with-fluid"
        end
      end
    end
    log(recipe.name.." DONE, recipe: ")
    log(serpent.dump(recipe))
  end
  ::continue::
end

-- replace belt products for multi-product recipes
-- TODO in future update -- will crash with multi-product recipes for now

-- remove belt recipes
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
    util.remove_raw("recipe", recipe.name)
  end
end

-- -- remove belt items
-- for belt in pairs(butil.belts) do
--   util.remove_raw("item", belt)
-- end
if mods.miniloader then
  for i, prefix in pairs({"space-", "deep-space-", table.unpack(prefixes)}) do
    for j, root in pairs({"miniloader-inserter", "filter-miniloader-inserter"}) do
      util.remove_raw("item", prefix..root)
    end
  end
end

-- remove belt entities
for belt in pairs(butil.belts) do
  util.remove_raw("entity", belt)
end
if mods.miniloader then
  for i, prefix in pairs({"space-", "deep-space-", table.unpack(prefixes)}) do
    for j, root in pairs({"miniloader-inserter", "filter-miniloader-inserter"}) do
      util.remove_raw("transport-belt", prefix..root)
      util.remove_raw("underground-belt", prefix..root)
      util.remove_raw("splitter", prefix..root)
      util.remove_raw("loader", prefix..root)
      if mods.miniloader then
        util.remove_raw("loader", prefix..root.."-inserter")
        util.remove_raw("inserter", prefix..root.."-inserter")
      end
    end
  end
end

-- remove belt unlocks
for i, tech in pairs(data.raw.technology) do
  butil.remove_belt_unlocks(tech)
end


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

if util.me.remove_loaders() then
  for i, tech in pairs(data.raw.technology) do
    butil.remove_belt_prereqs(tech)
  end

  for tech in pairs(butil.techs) do
    util.remove_raw("technology", tech)
  end
end


-- TODO make it work with WaterTurrets
