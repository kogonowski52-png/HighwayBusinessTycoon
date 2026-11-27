extends RefCounted
## Only called by the trusted reward path after native confirmation.

const IDS := ["freight_rush", "practice_bonus", "freight_tip", "yard_gift", "driver_rush"]
const DELIVERY_SECONDS := 20
const CLASS_SECONDS := 30
const DECORATION := "planter/2"

static func eligible(world: HbtCampaign, id: String, context: Dictionary) -> bool:
	var estate := world.current()
	var freight = world.freight
	var item := str(context.get("target", ""))
	match id:
		"freight_rush":
			var job: Dictionary = freight.jobs.get(item, {})
			if job.is_empty():
				return false
			return freight.vehicles[job.truck].home == estate.district and not job.get("rushed", false) 				and int(job.due) - estate.clock > DELIVERY_SECONDS + 7
		"driver_rush":
			var driver: Dictionary = freight.drivers.get(item, {})
			return driver.get("home", "") == estate.district and not driver.get("rushed", false) 				and int(driver.get("training", 0)) - estate.clock > CLASS_SECONDS
		"freight_tip":
			var recent: Dictionary = freight.receipts.get(estate.district, {})
			return not recent.is_empty() and not recent.get("tip", false) and str(recent.order) == item and int(recent.at) == int(context.get("stamp", -1))
		"practice_bonus":
			var result: Dictionary = estate.practice_state.get(item, {})
			return not result.is_empty() and not result.get("claimed_bonus", false) 				and int(result.ready) == int(context.get("stamp", -1))
		"yard_gift":
			return not estate.works.ownership.has(DECORATION)
	return false

static func grant(world: HbtCampaign, id: String, context: Dictionary) -> bool:
	var estate := world.current()
	var freight = world.freight
	var item := str(context.get("target", ""))
	if not eligible(world, id, context):
		return false
	match id:
		"freight_rush":
			freight.jobs[item].due = int(freight.jobs[item].due) - DELIVERY_SECONDS
			freight.jobs[item].rushed = true
		"driver_rush":
			freight.drivers[item].training = int(freight.drivers[item].training) - CLASS_SECONDS
			freight.drivers[item].rushed = true
		"freight_tip":
			var recent: Dictionary = freight.receipts[estate.district]
			estate.credit("cash", HbtAmount.from(recent.cash).times(20).divided(100))
			recent.tip = true
		"practice_bonus":
			var result: Dictionary = estate.practice_state[item]
			estate.credit("cash", HbtAmount.from(result.last).times(50).divided(100))
			result.claimed_bonus = true
		"yard_gift":
			estate.works.ownership[DECORATION] = true
			estate.works.revision += 1
	freight.revision += 1
	return true
