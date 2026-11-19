from pathlib import Path
import sys,json
from support import ROOT
from support import Harness
from support import CLASSES
count=0
for cls in CLASSES:
    games=[Harness(('source' if tree=='source' else 'optimized'),cls) for tree in ['source','optimized']]
    for faction in ['Alliance','Horde']:
        snapshots=[]
        for h in games:
            h.lua.globals().TEST_FACTION=faction
            h.lua.execute('''
                function G.Equip:WithoutItemPrime(fn,...)return fn(...)end
                if G.Data._expandedFaction[TEST_CLASS]~=TEST_FACTION then
                    assert(G.Data:ReleaseExpandedClass(TEST_CLASS));assert(G.Data:EnsureClassLoaded(TEST_CLASS));G.Data:BuildIndex()
                end
                G.Data.GetTopUpgradesForSlot=function()return {}end
                WEAPON_ROWS={}
                for _,slot in ipairs({'MainHand','SecondaryHand','Ranged'})do
                    G.Data:InvalidateQueryCache()
                    local done=0
                    G.Data:WarmWeaponSlotAsync(slot,function()done=done+1 end)
                    assert(done==1,'weapon callback')
                    assert(not G.Data._queryCache.warmFailed,'weapon warm failure')
                    local ids={slot}
                    for _,e in ipairs(G.Data._queryCache.candidates[slot])do ids[#ids+1]=e.id end
                    WEAPON_ROWS[#WEAPON_ROWS+1]=table.concat(ids,'|')
                end
            ''')
            snapshots.append(h.lua.eval('table.concat(WEAPON_ROWS,"\\n")'))
        assert snapshots[0]==snapshots[1],(cls,faction)
        count+=3
result={'async_weapon_queries':count,'native_equipment_checks':'stubbed','status':'passed'}
(ROOT/'weapon-results.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
