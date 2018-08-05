// Generic data stored in record
/datum/record
	var/id
	var/notes = "No notes found."

	var/cmp_field = "id"
	var/list/excluded_fields

/datum/record/proc/Copy(var/datum/copied)
	if(!copied)
		copied = new type()
	for(var/variable in src.vars)
		if((variable in SSrecords.excluded_fields) || (variable in excluded_fields)) continue
		if(istype(src.vars[variable], /datum/record) || istype(src.vars[variable], /list))
			copied.vars[variable] = src.vars[variable].Copy()
		else
			copied.vars[variable] = src.vars[variable]
	return copied

/datum/record/proc/Listify(var/deep = 1) // Mostyl to support old things or to use with serialization
	var/list/record = list()
	for(var/variable in src.vars)
		if(!(variable in list(SSrecords.excluded_fields, excluded_fields)))
			if(deep && (istype(src.vars[variable], /datum/record)))
				record[variable] = src.vars[variable].Listify()
			else if (istype(src.vars[variable], /list) || istext(src.vars[variable]) || isnum(src.vars[variable]))
				record[variable] = src.vars[variable]
	return record

// Record for storing general data, data tree top level datum
/datum/record/general
	var/datum/record/medical/medical
	var/datum/record/security/security
	var/name = "New Record"
	var/real_rank = "Unassigned"
	var/rank = "Unassigned"
	var/age = "Unknown"
	var/sex = "Unknown"
	var/fingerprint = "Unknown"
	var/phisical_status = "Active"
	var/mental_status = "Stable"
	var/species = "Unknown"
	var/home_system = "Unknown"
	var/citizenship = "Unknown"
	var/faction = "Unknown"
	var/religion = "Unknown"
	var/ccia_record = "No CCIA records found"
	var/ccia_actions = "No CCIA actions found"
	var/icon/photo_front
	var/icon/photo_side
	cmp_field = "name"
	excluded_fields = list("photo_front", "photo_side")

/datum/record/general/New(var/mob/living/carbon/human/H, var/nid)
	if (!H)
		var/mob/living/carbon/human/dummy = SSmob.get_mannequin("New record")
		photo_front = getFlatIcon(dummy, SOUTH, always_use_defdir = TRUE)
		photo_side = getFlatIcon(dummy, WEST, always_use_defdir = TRUE)
	else
		photo_front = getFlatIcon(H, SOUTH, always_use_defdir = TRUE)
		photo_side = getFlatIcon(H, WEST, always_use_defdir = TRUE)
	if(!nid) nid = generate_record_id()
	id = nid
	if(H)
		name = H.real_name
		real_rank = H.mind.assigned_role
		rank = GetAssignment(H)
		age = H.age
		fingerprint = md5(H.dna.uni_identity)
		sex = H.gender
		species = H.get_species()
		home_system = H.home_system
		citizenship = H.citizenship
		faction = H.personal_faction
		religion = H.religion
		ccia_record = H.ccia_record
		ccia_actions = H.ccia_actions
		if(H.gen_record && !jobban_isbanned(H, "Records"))
			notes = H.gen_record
	medical = new(H, id)
	security = new(H, id)


// Record for locked data
/datum/record/general/locked
	var/nid = ""
	var/enzymes
	var/identity
	var/exploit_record = "No additional information acquired."

/datum/record/general/locked/New(var/mob/living/carbon/human/H)
	// Only init things that aqre needed
	if(H)
		nid = md5("[H.real_name][H.mind.assigned_role]")
		enzymes = H.dna.SE
		identity = H.dna.UI
		if(H.exploit_record && !jobban_isbanned(H, "Records"))
			exploit_record = H.exploit_record

// Record for storing medical data
/datum/record/medical
	var/blood_type = "AB+"
	var/blood_dna = "63920c3ec24b5d57d459b33a2f4d6446"
	var/disabilities = "No disabilities have been declared."
	var/allergies = "No allergies have been detected in this patient."
	var/diseases = "No diseases have been diagnosed at the moment."
	var/list/comments = list()

/datum/record/medical/New(var/mob/living/carbon/human/H, var/nid)
	if(!nid) nid = generate_record_id()
	id = nid
	if(H)
		blood_type = H.b_type
		blood_dna = H.dna.unique_enzymes
		if(H.med_record && !jobban_isbanned(H, "Records"))
			notes = H.med_record

// Record for storing medical data
/datum/record/security
	var/criminal = "None"
	var/crimes = "There is no crime convictions."
	var/incidents = ""
	var/list/comments = list()

/datum/record/security/New(var/mob/living/carbon/human/H, var/nid)
	if(!nid) nid = generate_record_id()
	id = nid
	if(H)
		incidents = H.incidents
		if(H.sec_record && !jobban_isbanned(H, "Records"))
			notes = H.sec_record


// Digital warrant
/datum/record/warrant
	var/authorization = "Unauthorized"
	var/wtype = "Unknown"
	var/name = "Unknown"
	notes = "No charges present"
	cmp_field = "name"

var/warrant_uid = 0
/datum/record/warrant/New()
	id = warrant_uid++

// Digital warrant
/datum/record/virus
	var/name = "Unknown"
	var/description = ""
	var/antigen
	var/spread_type = "Unknown"
	cmp_field = "name"