"""Original district plans and business art directions for the second atlas chapter.

A business row contains its plot, facade proportions, economy, client lane, and service kind.
The coordinates are used identically by the paving, dispatch, workers and art placement.
"""
def venue(key, pl, en, marque, kind, x, z, width, length, height, wage, price, cost, gate, rep,
          lane="car", spacing=4.7, setback=5.5, bays=(1,18), shell=""):
    return dict(key=key, pl=pl, en=en, marque=marque, kind=kind,
                at=(x,z), size=(width,length,height), wage=wage, price=price, cost=cost, gate=gate,
                rep=rep, lane=lane, spacing=spacing, setback=setback, bays=bays, shell=shell or kind)


DISTRICTS = {
    "tropical": dict(
        map="Palmwater", colors=("f2cf9d","498f81","e58063","79bac0","5c685b"),
        surface=("abbd79","dfc98d","576f6f","7c8b81"), center=(-4.0,0.0,-8.8),
        road=[(-70,-4),(-52,-4),(-44,1),(-32,2),(-18,-2),(1,-2),(14,1),(28,3),(43,-1),(77,-1)],
        queue=55.0, ambient=11.5, board="pier", chapter=(71000,9200,5.4,1.45,"resort","noa"),
        fleet=["sunray","reefvan","dune_buggy","coast","cove","switchback","sundown","trail"],
        guests={"local":"dune_buggy","tourist":"reefvan","vip":"sunray","business":"courier","family":"reefvan","traveler":"sunray"},
        weights={"tourist":3.0,"family":1.8,"vip":2.1},
        specialties={"tourist":{"rent":60,"resort":52,"scooters":39,"market":31,"parking":24}},
        scenes=[
            venue("fuel","Paliwa Palmwater","Palmwater Fuel","PALMWATER", "fuel",0,-12,7.8,4.3,3.18,620,310,0,"",0),
            venue("rent","Wypożyczalnia Tide Keys","Tide Keys Car Rental","TIDE KEYS","rent",13,-13,7.9,4.5,3.21,920,560,6800,"fuel",9),
            venue("resort","Resort Lagoona","Lagoona Resort","LAGOONA RESORT","hotel",-21,-15,11.9,6.1,4.53,1440,1100,19200,"rent",22,spacing=5.6,setback=6.0,bays=(1,16,42)),
            venue("restaurant","Restauracja Reef Deck","Reef Deck Beach Dining","REEF DECK","food",-7,-26,8.9,5.2,3.3,1150,790,12400,"rent",14),
            venue("scooters","Skutery Coral Wheels","Coral Wheels Scooter Rental","CORAL WHEELS","scooter",24,-21,5.6,3.8,2.72,1080,670,23500,"resort",27,spacing=4.2),
            venue("market","Sklep Island Pantry","Island Pantry Travel Shop","ISLAND PANTRY","retail",-43,-10.3,6.5,4.4,3.0,1150,950,32600,"restaurant",34),
            venue("parking","Parking Drift Bay","Drift Bay Visitor Parking","DRIFT BAY","parking",38,-9.6,8.6,4.6,2.75,1400,1080,40700,"market",44),
            venue("wash","Myjnia Pearl Mist","Pearl Mist Car Spa","PEARL MIST","wash",-32,-24.5,7.6,5.2,3.34,1880,1470,56800,"resort",56,setback=4.6,bays=(1,22)),
        ]),
    "route66": dict(
        map="Copper Spur", colors=("f2cd9a","9a5550","dc9351","74a8a4","716052"),
        surface=("bb875f","e5b37a","655f57","928279"), center=(1.0,0.0,-8.1),
        road=[(-69,2),(-48,2),(-30,-2),(-12,-2),(1,2),(21,2),(40,-4),(76,-4)],
        queue=53.0, ambient=12.5, board="mesa", chapter=(142000,14200,5.9,1.55,"restoration","mona"),
        fleet=["oxbow","velvet","roamer","kestrel","mesa","sundown","cargo","regency"],
        guests={"local":"oxbow","tourist":"roamer","vip":"velvet","traveler":"velvet","family":"roamer","business":"oxbow"},
        weights={"traveler":2.6,"tourist":1.8,"vip":1.2},
        specialties={"traveler":{"restaurant":42,"motel":48,"restoration":26},"vip":{"restoration":65,"workshop":38}},
        scenes=[
            venue("fuel","Paliwa Copper Spur","Copper Spur Retro Fuel","COPPER SPUR","fuel",0,-9.5,9.8,4.7,3.42,1000,510,0,"",0),
            venue("restaurant","American Diner Sunliner","Sunliner American Diner","SUNLINER DINER","food",-16,-10,9.4,5.0,3.47,1420,940,11100,"fuel",9),
            venue("motel","Motel Comet Court","Comet Court Motel","COMET COURT","hotel",16,-12.4,12.5,5.5,4.22,1950,1360,21500,"restaurant",20,spacing=5.0,bays=(1,17,42)),
            venue("workshop","Warsztat Lowline","Lowline Classics Garage","LOWLINE CLASSICS","repair",-34,-10.9,7.8,5.6,3.37,2070,1470,36400,"motel",31,setback=4.8),
            venue("parts","Sklep Axle Supply","Axle Supply Parts Store","AXLE SUPPLY","retail",31,-16.0,6.8,4.8,2.98,2380,1540,52500,"workshop",42),
            venue("restoration","Centrum renowacji Brightsteel","Brightsteel Restoration","BRIGHTSTEEL","repair",42,-16.4,10.0,6.2,4.35,3500,2030,74400,"parts",55,spacing=5.55,setback=5.4,shell="restoration"),
        ]),
    "harbor": dict(
        map="Breakwater", colors=("bfd3cc","3f6872","d79555","79adb7","626e68"),
        surface=("768881","a7a887","4e636a","7f8990"), center=(-3.0,0.0,-18.0),
        road=[(-76,5),(-46,5),(-31,2),(-11,2),(20,2),(36,5),(81,5)],
        truck=[(-80,-18),(-51,-18),(-40,-21),(24,-21),(39,-18),(85,-18)],
        queue=61.0, truck_queue=62.0, ambient=17.4, board="ship", chapter=(225000,21700,5.9,1.38,"terminal","iman"),
        fleet=["container","cooler","forklift","courier","petrel","atlas","parcel","switchback"],
        guests={"local":"courier","business":"courier","trucker":"container","traveler":"cooler","family":"parcel","tourist":"switchback"},
        weights={"trucker":3.8,"business":2.0,"tourist":.35},
        specialties={"trucker":{"terminal":68,"transfer":58,"coldstore":40,"truck_service":48,"distribution":51,"truck_wash":22,"transport":52}},
        scenes=[
            venue("fuel","Paliwa Breakwater","Breakwater Fuel","BREAKWATER","fuel",-1,-7,7.9,4.5,3.27,1520,730,0,"",0),
            venue("terminal","Terminal Tidegate","Tidegate Container Terminal","TIDEGATE TERMINAL","freight",-21,-34,12.6,6.4,4.75,2560,1540,17400,"fuel",10,"truck",8.7,7.0,(1,15,43),"terminal"),
            venue("transfer","Centrum przeładunkowe Swing Dock","Swing Dock Transfer","SWING DOCK","freight",3,-34,11.5,6.4,4.5,3100,1880,31600,"terminal",19,"truck",8.5,7.1,(1,18,46),"transfer"),
            venue("coldstore","Chłodnia Northcold","Northcold Cold Storage","NORTHCOLD","cold",26,-34,11.3,6.2,4.69,3640,2080,48100,"transfer",29,"truck",8.3,7.1),
            venue("truck_service","Serwis Dockside Diesel","Dockside Diesel Service","DOCKSIDE DIESEL","repair",-45,-34,10.4,6.3,4.55,3810,2300,62500,"coldstore",36,"truck",8.4,7.1),
            venue("distribution","Centrum dystrybucji Cargo Circle","Cargo Circle Distribution","CARGO CIRCLE","freight",43,-34,10.7,6.1,4.42,4570,2770,80500,"truck_service",45,"truck",8.0,7.1,shell="distribution"),
            venue("truck_wash","Myjnia ciężarowa Blue Jet","Blue Jet Truck Wash","BLUE JET","wash",-58,-33.5,9.3,6.7,4.67,4670,2910,101000,"distribution",55,"truck",7.7,7.0),
            venue("transport","Baza transportowa Anchor Fleet","Anchor Fleet Base","ANCHOR FLEET","parking",57,-34.8,10.0,5.0,4.30,5230,3320,129000,"truck_wash",65,"truck",8.2,7.0,shell="transport"),
        ]),
    "luxury": dict(
        map="Gilded Mile", colors=("ede2c9","394e60","c3878e","8bc2c3","5f6d74"),
        surface=("919874","cbc49d","4a6570","78868a"), center=(-2,0,-8.1),
        road=[(-76,-1),(-54,-1),(-45,4),(-31,4),(-19,0),(16,0),(33,5),(81,5)],
        queue=64.0, ambient=18.2, board="fountain", chapter=(348000,33000,6.3,1.48,"tuning","selene"),
        fleet=["onyx","lumen","sovereign","sable","arrow","regency","orion","solstice"],
        guests={"local":"sovereign","business":"lumen","vip":"onyx","tourist":"sovereign","family":"sovereign","traveler":"lumen"},
        weights={"vip":5.1,"business":2.7,"tourist":1.4}, boulevard=True,
        specialties={"vip":{"dealership":76,"detail":58,"motel":45,"restaurant":43,"vip_park":40,"tuning":57}},
        scenes=[
            venue("fuel","Paliwa Aurum","Aurum Luxury Fuel","AURUM FORECOURT","fuel",0,-9.5,10.1,5.1,3.48,2320,1080,0,"",0),
            venue("dealership","Salon Onyx Atelier","Onyx Supercar Atelier","ONYX ATELIER","motor",-18,-13,10.9,6.3,4.17,4190,2400,27600,"fuel",13),
            venue("detail","Detailing Opaline","Opaline Detailing","OPALINE DETAIL","wash",-36,-13.3,8.5,5.6,3.54,4750,2750,46200,"dealership",23,setback=5.0),
            venue("motel","Hotel Gilded Garden","Gilded Garden Hotel","GILDED GARDEN","hotel",17,-15.3,12.1,6.3,5.17,5000,3130,71300,"detail",32,spacing=5.3,bays=(1,19,45)),
            venue("restaurant","Restauracja Marquee","Marquee Fine Dining","MARQUEE DINING","food",34,-12.2,9.4,5.9,3.62,5450,3620,103000,"motel",45),
            venue("vip_park","Parking VIP Pearl Court","Pearl Court VIP Parking","PEARL COURT","parking",45,-16.1,8.2,4.6,3.39,6190,3970,131000,"restaurant",56),
            venue("tuning","Centrum tuningu Velocity","Velocity Tuning","VELOCITY","repair",8.0,-27.0,8.9,5.8,3.89,7440,5100,171000,"vip_park",67,spacing=3.7,setback=5.2,shell="tuning"),
        ]),
    "japan": dict(
        map="Akari Junction", colors=("f0e0d4","595f82","d5809d","73a7ae","626179"),
        surface=("839376","bbb397","525c6a","79808f"), center=(-4,0,-10.1),
        road=[(-73,-2),(-55,-2),(-42,2),(-31,2),(-20,-3),(-1,-3),(13,1),(29,-3),(50,-1),(76,-1)],
        queue=59.0, ambient=13.8, board="gate", chapter=(525000,46300,5.75,1.37,"tuning","akio"),
        fleet=["akari","bento","ion","pulse","tandem","arrow","cove","courier"],
        guests={"local":"bento","business":"akari","vip":"akari","family":"bento","electric":"ion","traveler":"tandem","tourist":"akari"},
        weights={"electric":3.4,"business":1.5,"local":2.3,"vip":2.0}, look=3,
        specialties={"electric":{"charge":73,"restaurant":25,"market":32,"parking":28},"business":{"tuning":54,"market":39}},
        scenes=[
            venue("fuel","Paliwa Akari","Akari Fuel","AKARI FUEL","fuel",1,-12.5,8.7,4.9,3.4,3090,1560,0,"",0),
            venue("tuning","Akari Circuit Tuning","Akari Circuit Tuning","AKARI CIRCUIT","repair",-17,-13.6,9.4,5.6,3.73,5420,3260,39100,"fuel",12,setback=5.0,shell="tuning"),
            venue("restaurant","Ramen Lantern Bowl","Lantern Bowl Ramen","LANTERN BOWL","food",14,-12.8,7.5,4.7,3.23,6260,3770,67000,"tuning",24),
            venue("market","Sklep całodobowy Night Pantry","Night Pantry 24h Store","NIGHT PANTRY","retail",28,-12.4,7.1,4.6,3.09,6990,4200,91700,"restaurant",35),
            venue("wash","Myjnia Prism Jet","Prism Jet Automatic Wash","PRISM JET","wash",-33,-14.2,8.7,5.7,3.81,7830,4730,119000,"market",46,setback=4.8),
            venue("charge","Centrum EV Ion Court","Ion Court EV Centre","ION COURT","ev",-48,-12.2,10.1,4.8,3.24,8360,5190,151000,"wash",56,"electric",4.8,5.8),
            venue("parking","Parking Sakura Levels","Sakura Levels Parking","SAKURA LEVELS","parking",-8,-27.0,11.6,6.2,4.72,10400,6350,199000,"charge",68,spacing=5.3,bays=(1,17,43),shell="multilevel"),
        ]),
    "wilderness": dict(
        map="Timberline", colors=("d7c3a1","4e6b63","ba8058","87abb4","5c6865"),
        surface=("778a6d","a6ab8c","676d65","8e8d7a"), center=(0,0,-15.0),
        road=[(-74,5),(-53,5),(-36,0),(-23,3),(-10,3),(9,0),(27,3),(46,-1),(81,-1)],
        truck=[(-76,-17),(-50,-17),(-37,-22),(-23,-23),(-5,-18),(11,-19),(31,-23),(49,-21),(86,-21)],
        queue=60.0, truck_queue=65.0, ambient=15.7, board="ridge", chapter=(812000,65500,6.55,1.44,"logging","soren"),
        fleet=["timber","boreal","tandem","ridgeback","summit","cargo","parcel","switchback"],
        guests={"local":"boreal","business":"tandem","trucker":"timber","tourist":"boreal","family":"tandem","traveler":"boreal"},
        weights={"trucker":3.5,"tourist":2.6,"business":1.8},
        specialties={"trucker":{"logging":74,"haulage":58,"truck_service":58},"tourist":{"rent":51,"motel":68}},
        scenes=[
            venue("fuel","Paliwa Timberline","Timberline Fuel","TIMBERLINE","fuel",0,-10.2,8.8,4.9,3.32,4230,2240,0,"",0),
            venue("logging","Centrum transportu leśnego Logbridge","Logbridge Forestry Terminal","LOGBRIDGE","freight",-22,-36,12.4,6.2,4.65,7560,4450,57000,"fuel",12,"truck",8.7,7.0,(1,17,43),"logging"),
            venue("workshop","Warsztat Boreal 4×4","Boreal 4×4 Garage","BOREAL 4X4","repair",-17,-10.8,8.7,5.5,3.78,8290,5370,92000,"logging",23,setback=4.9),
            venue("haulage","Baza ciężkiego transportu Ridgeway","Ridgeway Heavy Haul","RIDGEWAY HAUL","freight",10,-34,11.6,6.1,4.63,9300,6200,132000,"workshop",34,"truck",8.2,7.0,shell="haulage"),
            venue("rent","Wypożyczalnia Trailhead","Trailhead Off-Road Rental","TRAILHEAD","rent",16,-11,8.8,5.4,3.41,10100,7040,181000,"haulage",46),
            venue("motel","Górski hotel Lakewatch","Lakewatch Mountain Lodge","LAKEWATCH","hotel",-37,-13,12.7,6.2,5.30,12600,8470,236000,"rent",58,spacing=5.6,bays=(1,18,44)),
            venue("truck_service","Serwis ciężarówek Frostline","Frostline Truck Service","FROSTLINE","repair",33,-35,11.4,6.2,4.54,13400,9510,295000,"motel",71,"truck",8.8,7.0),
        ]),
}

# Main route gates. The wallet and requirements are paid by the named sponsor.
GATES = {
    "tropical": ("metro","dealership",5,11,70),
    "route66": ("tropical","resort",5,12,74),
    "harbor": ("route66","restoration",5,14,78),
    "luxury": ("harbor","terminal",7,15,83),
    "japan": ("luxury","tuning",5,16,88),
    "wilderness": ("japan","charge",6,17,94),
}
