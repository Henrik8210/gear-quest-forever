from pathlib import Path
import sys,json
from support import ROOT
from support import Harness
source=Harness('source','WARRIOR')
text=Harness('optimized','WARRIOR')
items=[item for item,_ in source.g.Data.coordinates.items()]
source.lua.globals().ITEMS=source.lua.table_from(items)
text.lua.globals().ITEMS=text.lua.table_from(items)
source.lua.execute('''
    function CoordinateFlags()
        local out={}
        for _,item in ipairs(ITEMS)do
            local row=G.Data.coordinates[item]
            local openWorld=G.Data.PinIgnoresFactionZone and G.Data:PinIgnoresFactionZone(row)
            for _,side in ipairs({'Alliance','Horde'})do
                local allowed=not row or not row.spots or #row.spots==0
                for _,spot in ipairs(row and row.spots or {})do allowed=allowed or G.Data:SpotVisible(spot,side,openWorld)end
                out[#out+1]=tostring(allowed)
            end
        end
        return table.concat(out,',')
    end
''')
text.lua.execute('''
    function CoordinateFlags()
        local out={}
        for _,item in ipairs(ITEMS)do
            for _,side in ipairs({'Alliance','Horde'})do out[#out+1]=tostring(G.Data:CoordinateAllowsFaction(item,side))end
        end
        return table.concat(out,',')
    end
''')
assert source.lua.eval('CoordinateFlags()')==text.lua.eval('CoordinateFlags()')
assert not text.loaded
result={'coordinate_items':len(items),'faction_comparisons':len(items)*2,'status':'passed','maps_loaded_normally':True}
(ROOT/'map-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
