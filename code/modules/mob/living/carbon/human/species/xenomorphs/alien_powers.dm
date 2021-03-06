/proc/alien_queen_exists(var/ignore_self,var/mob/living/carbon/human/self)
	for(var/mob/living/carbon/human/Q in living_mob_list)
		if(self && ignore_self && self == Q)
			continue
		if(Q.species.name != "Xenomorph Queen")
			continue
		if(!Q.key || !Q.client || Q.stat)
			continue
		return 1
	return 0

/mob/living/carbon/human/proc/gain_plasma(var/amount)

	var/obj/item/organ/xenos/plasmavessel/I = internal_organs_by_name["plasma vessel"]
	if(!istype(I)) return

	if(amount)
		I.stored_plasma += amount
	I.stored_plasma = max(0,min(I.stored_plasma,I.max_plasma))

/mob/living/carbon/human/proc/check_alien_ability(var/cost,var/needs_foundation,var/needs_organ)

	var/obj/item/organ/xenos/plasmavessel/P = internal_organs_by_name["plasma vessel"]
	if(!istype(P))
		to_chat(src, "<span class='danger'>Your plasma vessel has been removed!</span>")
		return

	if(needs_organ)
		var/obj/item/organ/I = internal_organs_by_name[needs_organ]
		if(!I)
			to_chat(src, "<span class='danger'>Your [needs_organ] has been removed!</span>")
			return
		else if((I.status & ORGAN_CUT_AWAY) || I.is_broken())
			to_chat(src, "<span class='danger'>Your [needs_organ] is too damaged to function!</span>")
			return

	if(P.stored_plasma < cost)
		to_chat(src, "<span class='warning'>You don't have enough phoron stored to do that.</span>")
		return 0

	if(needs_foundation)
		var/turf/T = get_turf(src)
		var/has_foundation
		if(T)
			//TODO: Work out the actual conditions this needs.
			if(!(istype(T,/turf/space)))
				has_foundation = 1
		if(!has_foundation)
			to_chat(src, "<span class='warning'>You need a solid foundation to do that on.</span>")
			return 0

	P.stored_plasma -= cost
	return 1

// Free abilities.
/mob/living/carbon/human/proc/transfer_plasma(mob/living/carbon/human/M as mob in oview())
	set name = "Transfer Plasma"
	set desc = "Transfer Plasma to another alien"
	set category = "Abilities"

	if (get_dist(src,M) <= 1)
		to_chat(src, "<span class='alium'>You need to be closer.</span>")
		return

	var/obj/item/organ/xenos/plasmavessel/I = M.internal_organs_by_name["plasma vessel"]
	if(!istype(I))
		to_chat(src, "<span class='alium'>Their plasma vessel is missing.</span>")
		return

	var/amount = input("Amount:", "Transfer Plasma to [M]") as num
	if (amount)
		amount = abs(round(amount))
		if(check_alien_ability(amount,0,"plasma vessel"))
			M.gain_plasma(amount)
			to_chat(M, "<span class='alium'>[src] has transfered [amount] plasma to you.</span>")
			to_chat(src, "<span class='alium'>You have transferred [amount] plasma to [M].</span>")
	return

// Queen verbs.
/mob/living/carbon/human/proc/lay_egg()

	set name = "Lay Egg (75)"
	set desc = "Lay an egg to produce huggers to impregnate prey with."
	set category = "Abilities"

	if(!config.aliens_allowed)
		to_chat(src, "You begin to lay an egg, but hesitate. You suspect it isn't allowed.")
		verbs -= /mob/living/carbon/human/proc/lay_egg
		return

	if(locate(/obj/structure/alien/egg) in get_turf(src))
		to_chat(src, "There's already an egg here.")
		return

	if(check_alien_ability(75,1,"egg sac"))
		visible_message("<span class='alium'><B>[src] has laid an egg!</B></span>")
		new /obj/structure/alien/egg(loc)

	return

// Drone verbs.
/mob/living/carbon/human/proc/evolve()
	set name = "Evolve (500)"
	set desc = "Produce an interal egg sac capable of spawning children. Only one queen can exist at a time."
	set category = "Abilities"

	if(alien_queen_exists())
		to_chat(src, "<span class='notice'>We already have an active queen.</span>")
		return

	if(check_alien_ability(500))
		visible_message("<span class='alium'><B>[src] begins to twist and contort!</B></span>", "<span class='alium'>You begin to evolve!</span>")
		src.set_species("Xenomorph Queen")

	return

/mob/living/carbon/human/proc/plant()
	set name = "Plant Weeds (50)"
	set desc = "Plants some alien weeds"
	set category = "Abilities"

	if(check_alien_ability(50,1,"resin spinner"))
		visible_message("<span class='alium'><B>[src] has planted some alien weeds!</B></span>")
		var/obj/structure/alien/weeds/node/new_node = new(get_turf(src))
		new_node.linked_node = new_node
	return

/mob/living/carbon/human/proc/corrosive_acid(O as obj|turf in oview(1)) //If they right click to corrode, an error will flash if its an invalid target./N
	set name = "Corrosive Acid (200)"
	set desc = "Drench an object in acid, destroying it over time."
	set category = "Abilities"

	if(!O in oview(1))
		to_chat(src, "<span class='alium'>[O] is too far away.</span>")
		return

	// OBJ CHECK
	var/cannot_melt
	if(isobj(O))
		var/obj/I = O
		if(I.unacidable)
			cannot_melt = 1
	else
		if(istype(O, /turf/simulated/wall))
			var/turf/simulated/wall/W = O
			if(W.material.flags & MATERIAL_UNMELTABLE)
				cannot_melt = 1
		else if(istype(O, /turf/simulated/floor))
			var/turf/simulated/floor/F = O
			if(F.flooring && (F.flooring.flags & TURF_ACID_IMMUNE))
				cannot_melt = 1

	if(cannot_melt)
		to_chat(src, "<span class='alium'>You cannot dissolve this object.</span>")
		return

	if(check_alien_ability(200,0,"acid gland"))
		new /obj/effect/acid(get_turf(O), O)
		visible_message("<span class='alium'><B>[src] vomits globs of vile stuff all over [O]. It begins to sizzle and melt under the bubbling mess of acid!</B></span>")

	return

/mob/living/carbon/human/proc/neurotoxin(mob/target as mob in oview())
	set name = "Spit Neurotoxin (50)"
	set desc = "Spits neurotoxin at someone, paralyzing them for a short time if they are not wearing protective gear."
	set category = "Abilities"

	if(!check_alien_ability(50,0,"acid gland"))
		return

	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		to_chat(src, "You cannot spit neurotoxin in your current state.")
		return

	visible_message("<span class='warning'>[src] spits neurotoxin at [target]!</span>", "<span class='alium'>You spit neurotoxin at [target].</span>")

	var/obj/item/projectile/energy/neurotoxin/A = new /obj/item/projectile/energy/neurotoxin(usr.loc)
	A.launch_projectile(target,get_organ_target())

/mob/living/carbon/human/proc/resin() // -- TLE
	set name = "Secrete Resin (75)"
	set desc = "Secrete tough, malleable resin."
	set category = "Abilities"

	var/choice = input("Choose what you wish to shape.","Resin building") as null|anything in list("resin door","resin wall","resin membrane","resin nest") //would do it through typesof but then the player choice would have the type path and we don't want the internal workings to be exposed ICly - Urist
	if(!choice)
		return

	if(!check_alien_ability(75,1,"resin spinner"))
		return

	visible_message("<span class='warning'><B>[src] vomits up a thick purple substance and begins to shape it!</B></span>", "<span class='alium'>You shape a [choice].</span>")
	switch(choice)
		if("resin door")
			new /obj/structure/simple_door/resin(loc)
		if("resin wall")
			new /obj/structure/alien/resin/wall(loc)
		if("resin membrane")
			new /obj/structure/alien/resin/membrane(loc)
		if("resin nest")
			new /obj/structure/bed/nest(loc)
	return

mob/living/carbon/human/proc/xeno_infest(mob/living/carbon/human/M as mob in oview())
	set name = "Infest (500)"
	set desc = "Link a victim to the hivemind."
	set category = "Abilities"

	if(!M.Adjacent(src))
		to_chat(src, "<span class='warning'>They are too far away.</span>")
		return

	if(!M.mind)
		to_chat(src, "<span class='warning'>This mindless flesh adds nothing to the hive.</span>")
		return

	if(M.species.get_bodytype() == "Xenomorph" || !isnull(M.internal_organs_by_name["hive node"]))
		to_chat(src, "<span class='warning'>They are already part of the hive.</span>")
		return

	var/obj/item/organ/affecting = M.get_organ("chest")
	if(!affecting || (affecting.status & ORGAN_ROBOT))
		to_chat(src, "<span class='warning'>This form is not compatible with our physiology.</span>")
		return

	src.visible_message("<span class='danger'>\The [src] crouches over \the [M], extending a hideous protuberance from its head!</span>")

	if(!do_after(src, 150))
		return

	if(!M || !M.Adjacent(src))
		to_chat(src, "<span class='warning'>They are too far away.</span>")
		return

	if(M.species.get_bodytype() == "Xenomorph" || !isnull(M.internal_organs_by_name["hive node"]) || !affecting || (affecting.status & ORGAN_ROBOT))
		return

	if(!check_alien_ability(500,1,"egg sac"))
		return

	src.visible_message("<span class='danger'>\The [src] regurgitates something into \the [M]'s torso!</span>")
	to_chat(M, "<span class='danger'>A hideous lump of alien mass strains your ribcage as it settles within!</span>")
	var/obj/item/organ/xenos/hivenode/node = new(affecting)
	node.replaced(M,affecting)