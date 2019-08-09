/datum/game_mode/hell_march
	name = "Gangmageddon"
	config_tag = "gangmageddon"
	antag_flag = ROLE_GANG
	restricted_jobs = list("Security Officer", "Warden", "Detective", "AI", "Cyborg","Captain", "Head of Personnel", "Head of Security")
	required_players = 25
	required_enemies = 3
	recommended_enemies = 6
	enemy_minimum_age = 14

	announce_span = "danger"
	announce_text = "A violent turf war has erupted on the station!\n\
	<span class='danger'>Gangsters</span>: Take over the station with a dominator.\n\
	<span class='notice'>Crew</span>: Prevent the gangs from expanding and initiating takeover."
	var/area/target_armory
	var/area/target_brig
	var/area/target_equip
	var/area/target_hos
	var/area/target_captain
	var/area/target_captain2
	var/area/target_science
	var/area/target_hop
	var/area/target_det
	var/area/target_ward
	var/area/target_atmos
	var/list/datum/mind/gangboss_candidates = list()
	var/gangs_to_create = 2

/datum/game_mode/hell_march/pre_setup()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs

	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"

	//Spawn more bosses depending on server population
	if(prob(num_players()) && num_players() > 1.5*required_players)
		gangs_to_create++
	if(prob(num_players()) && num_players() > 2*required_players)
		gangs_to_create++
	gangs_to_create = min(gangs_to_create, GLOB.possible_gangs.len)

	for(var/i in 1 to gangs_to_create)
		if(!antag_candidates.len)
			break
		for(var/j in 1 to 3)
			if(!antag_candidates.len)
				break
			var/datum/mind/bossman = pick_n_take(antag_candidates)
			antag_candidates -= bossman
			gangboss_candidates += bossman
			bossman.restricted_roles = restricted_jobs

	if(!gangboss_candidates.len)
		return

	SSjob.DisableJob(/datum/job/captain)
	SSjob.DisableJob(/datum/job/hop)
	SSjob.DisableJob(/datum/job/hos)
	SSjob.DisableJob(/datum/job/warden)
	SSjob.DisableJob(/datum/job/detective)
	SSjob.DisableJob(/datum/job/officer)
	SSjob.DisableJob(/datum/job/lawyer)
	SSjob.DisableJob(/datum/job/ai)
	SSjob.DisableJob(/datum/job/cyborg)

	// For removing problematic items
	target_armory = locate(/area/ai_monitored/security/armory) in GLOB.sortedAreas
	target_hos = locate(/area/crew_quarters/heads/hos) in GLOB.sortedAreas
	target_brig = locate(/area/security/brig) in GLOB.sortedAreas
	target_equip = locate(/area/security/main) in GLOB.sortedAreas
	target_ward = locate(/area/security/warden) in GLOB.sortedAreas
	target_det = locate(/area/security/detectives_office) in GLOB.sortedAreas
	target_captain = locate(/area/crew_quarters/heads/captain/private) in GLOB.sortedAreas
	target_hop = locate(/area/crew_quarters/heads/hop) in GLOB.sortedAreas
	target_science = locate(/area/science/mixing) in GLOB.sortedAreas
	target_atmos = locate(/area/engine/atmos) in GLOB.sortedAreas

	for(var/area/crew_quarters/heads/captain/C in GLOB.sortedAreas)
		if(C != /area/crew_quarters/heads/captain/private)
			target_captain2 = C
			break
	gangpocalypse()

/datum/game_mode/hell_march/post_setup()
	var/list/all_gangs = GLOB.possible_gangs.Copy()
	for(var/i in 1 to gangs_to_create)
		if(!gangboss_candidates.len)
			break
		var/gang_type = pick_n_take(all_gangs)
		var/datum/team/gang/passione = new gang_type
		for(var/j in 1 to 3)
			if(!gangboss_candidates.len)
				break
			var/datum/mind/gangstar = pick_n_take(gangboss_candidates)
			passione.leaders += gangstar
			var/datum/antagonist/gang/boss/giorno = new
			gangstar.add_antag_datum(giorno, passione)
			var/obj/item/device/gangtool/hell_march/HM = new /obj/item/device/gangtool/hell_march(gangstar.current)
			HM.register_device(gangstar.current)
	for(var/mob/living/M in GLOB.player_list)
		if(!M.mind.has_antag_datum(/datum/antagonist/gang))
			M.mind.add_antag_datum(/datum/antagonist/vigilante)
	addtimer(CALLBACK(GLOBAL_PROC, .proc/priority_announce, "Excessive costs associated with lawsuits from employees injured by Security and Synthetics have compelled us to re-evaluate the personnel budget for new stations. Accordingly, this station will be expected to operate without Security or Synthetic assistance. In the event that criminal enterprises seek to exploit this situation, we have implanted all crew with a device that will assist and incentivize the removal of all contraband and criminals.", "Nanotrasen Board of Directors"), 8 SECONDS)

/datum/game_mode/hell_march/proc/cleanup(area/target)
	if(target)
		for(var/turf/T in target.GetAllContents())
			CHECK_TICK
			for(var/obj/item/I in T.GetAllContents())
				if(istype(I, /obj/item/weapon))
					qdel(I)
				if(istype(I, /obj/item/clothing))
					qdel(I)
				if(istype(I, /obj/item/gun))
					qdel(I)

/datum/game_mode/hell_march/proc/gangpocalypse()
	set waitfor = FALSE
	cleanup(target_captain)
	cleanup(target_captain2)
	cleanup(target_armory)
	cleanup(target_brig)
	cleanup(target_equip)
	cleanup(target_hos)
	cleanup(target_det)
	cleanup(target_ward)
	cleanup(target_hop)
	if(target_science)
		for(var/obj/item/transfer_valve/TTV in target_science.GetAllContents())
			qdel(TTV)
	if(target_atmos)
		for(var/turf/open/floor/engine/plasma/T in target_atmos.GetAllContents())
			CHECK_TICK
			T.ChangeTurf(/turf/open/floor/engine/airless)
			new /obj/structure/barricade/wooden(T)
