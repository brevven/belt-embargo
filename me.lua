local me = {}

me.name = "belt-embargo"

function me.remove_loaders()
  return me.get_setting("belt-embargo-remove-loaders")
end

function me.remove_techs()
  return me.get_setting("belt-embargo-remove-techs")
end


function me.get_setting(name)
  if settings.startup[name] == nil then
    return nil
  end
  return settings.startup[name].value
end

me.bypass = {}

function me.add_modified(name) 
  if me.get_setting(me.name.."-list") then 
    table.insert(me.list, name)
  end
end

return me
