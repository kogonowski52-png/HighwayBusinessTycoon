extends RefCounted

# Kind, geometry, service preferences and reward in slices of the normal invoice.
const MOMENTS := [
	{"id":"celebrity", "guest":"vip", "model":"velvet", "services":["vip_park","motel","restaurant","fuel"], "reward":2, "color":"eac17f"},
	{"id":"sport", "guest":"business", "model":"onyx", "services":["wash","tuning","detail","fuel"], "reward":1, "color":"ef8c81"},
	{"id":"coach", "guest":"tourist", "model":"reefvan", "services":["motel","resort","restaurant","fuel"], "reward":1, "color":"78c4a6"},
	{"id":"convoy","guest":"trucker", "model":"timber", "services":["haulage","logging","truck_park","truck","fuel"], "reward":2, "color":"bdab87"},
	{"id":"delivery","guest":"trucker","model":"cooler","services":["warehouse","coldstore","terminal","logistics","truck"],"reward":2,"color":"a8c4d6"},
	{"id":"festival","guest":"local","model":"sunray","services":["restoration","restaurant","market","fuel"], "reward":1, "color":"ffca82"},
	{"id":"collector","guest":"vip","model":"lumen","services":["dealership","vip_park","motel","fuel"], "reward":2, "color":"d0aade"},
	{"id":"holiday","guest":"family","model":"roamer","services":["resort","rent","cafe","market","fuel"], "reward":1, "color":"8ec5b6"},
]
