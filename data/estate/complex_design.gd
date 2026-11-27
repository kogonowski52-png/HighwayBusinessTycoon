extends RefCounted

const PALETTE := ["7496a2", "d3a169", "728d71", "8b75a4", "c76d58"]
const ACCENTS := ["c6e0d8", "f0d396", "e4cf9a", "d8bde3", "eac2a4"]
const STYLES := {
	"facade": [["Porcelana morska","Sea porcelain"], ["Piaskowiec","Sandstone"], ["Ziołowa zieleń","Herb green"], ["Fioletowy granit","Violet granite"], ["Cegła Copper Mile","Copper Mile brick"]],
	"roof": [["Blacha patynowana","Patina roofing"], ["Miedź szczotkowana","Brushed copper"], ["Zielony łupek","Green slate"], ["Grafit ametystowy","Amethyst graphite"], ["Gont gliniany","Clay shingle"]],
	"canopy": [["Tkanina turkusowa","Turquoise fabric"], ["Płótno słoneczne","Sunwashed canvas"], ["Kremowe pasy","Cream stripes"], ["Śliwkowa markiza","Plum awning"], ["Pomarańcz retro","Retro orange"]],
	"sign": [["Tablica Wave","Wave sign"], ["Szyld Sunline","Sunline sign"], ["Tablica Elm","Elm sign"], ["Szyld Nightway","Nightway sign"], ["Pylon Copper","Copper pylon"]],
	"lights": [["Lampy Port","Port lamps"], ["Latarnie Golden","Golden lanterns"], ["Lampki Forest","Forest lighting"], ["Neon Orchid","Orchid neon"], ["Lampy Comet","Comet lamps"]],
	"fence": [["Słupki Tide","Tide posts"], ["Ogrodzenie Ranch","Ranch rails"], ["Palisada Orchard","Orchard pickets"], ["Krata Metro","Metro lattice"], ["Bariera Sunrise","Sunrise bollards"]],
	"paving": [["Chodnik Port","Port walk"], ["Wapień","Limestone walk"], ["Kamień rzeczny","Riverstone walk"], ["Mozaika Akari","Akari mosaic"], ["Kostka klasyczna","Classic brick"]],
	"plants": [["Palmy Palmwater","Palmwater palms"], ["Agawy Copper","Copper agaves"], ["Świerki Snowline","Snowline spruce"], ["Wiśnie Akari","Akari cherries"], ["Krzewy Coral Key","Coral Key shrubs"]],
	"planter": [["Koryto Port","Port trough"], ["Donica Sun","Sun planter"], ["Skrzynia Orchard","Orchard box"], ["Donica Lotus","Lotus planter"], ["Donice Paloma","Paloma pair"]],
	"bench": [["Ławka Dock","Dock bench"], ["Ławka Rail","Rail bench"], ["Ławka Greenbank","Greenbank bench"], ["Ławka Arc","Arc bench"], ["Siedziska Comet","Comet seats"]],
	"fountain": [["Źródło Bluecurrent","Bluecurrent spring"], ["Fontanna Słońce","Sun fountain"], ["Kaskada Valley","Valley cascade"], ["Oczko Lotus","Lotus pond"], ["Fontanna Copper","Copper fountain"]],
	"billboard": [["Witamy w Palmwater","Palmwater welcome"], ["Trasa 17 Vintage","Route 17 vintage"], ["Zielona Dolina","Valley Green"], ["Akari Circuit","Akari Circuit"], ["Zlot Copper Spur","Copper Spur rally"]],
}
const INFRASTRUCTURE := {
	"roads": ["Drogi wewnętrzne","Internal roads"], "entry": ["Wjazd","Entrance"],
	"exit": ["Wyjazd","Exit"], "junction": ["Skrzyżowanie","Junction"], "roundabout": ["Rondo kierunkowe","Roundabout guidance"],
	"parking": ["Organizacja parkingu","Parking layout"], "bays": ["Stanowiska obsługi","Service bays"],
	"signals": ["Sygnalizacja","Lane signals"], "walkways": ["Chodniki","Walkways"], "lamps": ["Oświetlenie uliczne","Street lighting"],
}

const CAMPAIGNS := {
	"roadside": {"name":["Reklamy przydrożne","Roadside advertising"], "seconds":300, "cost":48, "traffic":1.25, "group":"traveler", "site":""},
	"fuel": {"name":["Promocja paliwowa","Fuel promotion"], "seconds":260, "cost":40, "traffic":1.11, "group":"local", "site":"fuel"},
	"wash": {"name":["Promocja myjni","Car wash promotion"], "seconds":260, "cost":38, "traffic":1.14, "group":"family", "site":"wash"},
	"dining": {"name":["Promocja restauracji","Dining promotion"], "seconds":420, "cost":58, "traffic":1.14, "group":"family", "site":"food"},
	"tourism": {"name":["Kampania turystyczna","Tourism campaign"], "seconds":480, "cost":65, "traffic":1.19, "group":"tourist", "site":"hotel"},
	"truck": {"name":["Kampania ciężarowa","Freight campaign"], "seconds":420, "cost":62, "traffic":1.15, "group":"trucker", "site":"freight"},
	"vip": {"name":["Kampania VIP","VIP campaign"], "seconds":360, "cost":70, "traffic":1.13, "group":"vip", "site":"vip"},
}

const AUDITS := {
	"fuel": {"name":["Kontrola jakości stacji","Fuel service inspection"], "site":"fuel", "level":8, "rating":63, "sales":12},
	"workshop": {"name":["Inspekcja warsztatu","Workshop inspection"], "site":"workshop", "level":12, "rating":66, "sales":15},
	"dining": {"name":["Ocena restauracji","Dining review"], "site":"food", "level":14, "rating":68, "sales":20},
	"hotel": {"name":["Audyt hotelu","Hotel audit"], "site":"hotel", "level":16, "rating":70, "sales":18},
	"freight": {"name":["Sprawność centrum logistycznego","Logistics efficiency"], "site":"freight", "level":18, "rating":68, "sales":22},
	"estate": {"name":["Konkurs kompleksów","Best complex award"], "site":"", "level":23, "rating":75, "sales":65},
}
