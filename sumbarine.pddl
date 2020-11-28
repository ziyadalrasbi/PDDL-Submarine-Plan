

(define (domain submarine)
    (:requirements
        :strips :typing
    )

    (:types
        status mineral mainsub section person location minisub report - main ; the main super types and other types that are not subtypes
        bridge launchbay sciencelab sickbay storage - section ; the different sections of the submarine
        engineer engineerc captain scientist security navigator doctor military - person ; the different personnel. engineerc is the engineer required for controlling the minisub launch controls. engineer is a regular engineer
        ridge abyssal vortex port base - location ; the different locations in the underwater regions
        drillsub expsub militarysub - minisub ; minisub types
        drillreport basereport sensorreport vortexreport militaryreport - report ; report types
        active down - status ; type for the status of the shield, either active or down
    )
    
    (:predicates

        ; navigation and mapping predicates
        (orderGiven ?x - captain ?y - navigator) ; captain giving an order to the navigator to move
        (subAt ?x - mainsub ?y - location) ; location of the main submarine
        (map ?x - location ?y - location) ; map of the underwater regions
        (personAt ?x - person ?y - (either section location)) ; location of a personnel
        (path ?x - section ?y - section) ; map of the submarine

        ; mini sub predicates
        (miniSubAt ?x - minisub ?y - (either location section)) ; location of a minisub
        (drillSubDeployed ?x - drillsub) ; checking if a drill mini sub has been deployed
        (baseSubDeployed ?x - expsub); checking if an exploration mini sub has been deployed for a base mission
        (sensorSubDeployed ?x - expsub); checking if an exploration mini sub has been deployed for a sensor mission
        (baseSubNoSecurityDeployed ?x - expsub) ; checking if an exploration mini sub has been deployed for a base mission but without security in it

        ; ridge predicates
        (mineralsAt ?x - mineral ?y - (either ridge launchbay sciencelab)) ; location of the minerals
        (mineralsRetrieved ?x - mineral) ; stating whether or not the minerals have been retrieved

        ; abyssal base predicates
        (leadersMet ?x - base) ; states whether the leaders of a base have been met
        (atlanteanTakeover ?x - base) ; checking if a base has been taken over by atlanteans
        (baseAt ?x - abyssal) ; checking if a base exists at an abyssal region

        ; abyssal sensor predicates
        (sensorsSetup) ; boolean stating whether the sensors have been setup or not
        (sensorsNeeded ?x - abyssal) ; checking if sensors are needed at an abyssal region

        ; vortex predicates
        (vortexScanned ?x - vortex) ; scanning a vortex
        (shieldStatus ?x - status) ; checking the status of the shield for the vortex mission

        ; misc predicates
        (injured ?x - person) ; checking if a personnel has been injured
        (missionCompleted) ; the final mission completed
        (reportGenerated ?x - report) ; generating a report after mission completion
        
        ; additional feature predicates
        (militaryDeployed ?x - military) ; checking if military personnel have been deployed
        (militarySubDeployed ?x - militarysub) ; checking if a military mini sub has been deployed
        (baseCaptured ?x - base) ; stating that a base has been captured
        (atlanteansAt ?x - base) ; checking if atlanteans are at a base
        
    )




; NAVIGATION SECTION
; this section is for making the actions for movement



; action for moving the main submarine around the underwater regions
(:action navigate 
    :parameters
        (?c - captain ?n - navigator ?b - bridge ?x - location ?y - location ?s - mainsub)
    :precondition
        (and
            (personAt ?c ?b) ; captain must be in bridge
            (personAt ?n ?b) ; navigator must be in bridge
            (orderGiven ?c ?n) ; captain must have given order to navigator
            (subAt ?s ?x) ; the initial location of the submarine
            (map ?x ?y) ; map of the underwater regions
        )
    :effect
        (and
            (not(subAt ?s ?x)) ; sub will no longer be at start location
            (subAt ?s ?y) ; sub will be at end location
        )
)

; action for moving the personnel around the submarine
(:action move
    :parameters
        (?p - person ?x - section ?y - section)
    :precondition
        (and
            (personAt ?p ?x) ; initial location of the person
            (path ?x ?y) ; map of the submarine sections
        )
    :effect
        (and
            (not (personAt ?p ?x)) ; person will no longer be at start location
            (personAt ?p ?y) ; person will be at end location
        )
)  




; DEPLOYING SECTION
; this section is for making actions that deploy personnel to a certain region for a certain mission
; missions are not completed in this section, personnel are only deployed



; action for deploying the drill mini sub to a ridge
(:action minideployeddrill
    :parameters 
        (?m - drillsub ?e - engineerc ?l - launchbay ?c - location ?d - ridge ?s - mainsub)
    :precondition 
        (and 
            (personAt ?e ?l) ; engineer needed at the launchbay to control the launch of the minisub
            (miniSubAt ?m ?l) ; minisub at the launchbay, must be a drilling sub
            (subAt ?s ?d) ; main submarine must be at the ridge region too, to deploy the mini sub 
        )
    :effect 
        (and 
            (drillSubDeployed ?m) ; drill sub has now been deployed 
            (not(miniSubAt ?m ?l)) ; drill sub is no longer at the launchbay
            (miniSubAt ?m ?d) ; drill sub is at the ridge
        )
)

; action for deploying the exploration minisub to an abyssal plain for the sensor mission
(:action minideployedsensor
    :parameters 
        (?m - expsub ?e - engineerc ?l - launchbay ?c - location ?d - abyssal ?s - mainsub ?p - engineer)
    :precondition 
        (and 
            (personAt ?p ?l) ; engineer needed to be deployed on this mission
            (personAt ?e ?l) ; engineer needed at the launchbay to control the launch of the minisub
            (miniSubAt ?m ?l) ; minisub at the launchbay, must be an exploration sub
            (subAt ?s ?d) ; main submarine must be at the abyssal region too, to deploy the mini sub  
        )
    :effect 
        (and 
            (sensorSubDeployed ?m) ; exploration sub has now been deployed 
            (not(miniSubAt ?m ?l)) ; exploration sub is no longer at the launchbay
            (miniSubAt ?m ?d) ; exploration sub is at the abyssal
            (not(personAt ?p ?l)) ; engineer is no longer at the launchbay
            (personAt ?p ?d) ; engineer is at the abyssal
        )
)

; action for deploying the exploration minisub to an abyssal plain for the base checking mission
; to clarify, for my design I stricly made it that only the security personnel and the captain can be deployed for this mission
; this action prevents the captain from being injured as the security is present
(:action minideployedbase
    :parameters 
        (?m - expsub ?e - engineerc ?l - launchbay ?c - location ?d - abyssal ?s - mainsub ?p - captain ?q - security)
    :precondition 
        (and 
            (personAt ?p ?l) ; captain needed to be deployed on this mission
            (personAt ?q ?l) ; security needed to be deployed on this mission
            (personAt ?e ?l) ; engineer needed at the launchbay to control the launch of the minisub
            (miniSubAt ?m ?l) ; minisub at the launchbay, must be an exploration sub
            (subAt ?s ?d) ; main submarine must be at the abyssal region too, to deploy the mini sub 
        )
    :effect 
        (and 
            (baseSubDeployed ?m) ; exploration sub has now been deployed 
            (not(miniSubAt ?m ?l)) ; exploration sub is no longer at the launchbay
            (miniSubAt ?m ?d) ; exploration sub is at the abyssal
            (not(personAt ?p ?l)) ; captain is no longer at the launchbay
            (personAt ?p ?d) ; captain is at the abyssal
            (not(personAt ?q ?l)) ; security is no longer at the launchbay
            (personAt ?q ?d) ; security is at the abyssal
        )
)

; action for deploying the exploration minisub to an abyssal plain for the base checking mission, however security is not present
; to clarify, for my design I strictly made it that if the security is not present, the base must have been taken over and the captain will be injured
(:action minideployedbasenosecurity
    :parameters 
        (?m - expsub ?e - engineerc ?l - launchbay ?c - location ?d - abyssal ?s - mainsub ?p - captain)
    :precondition 
        (and 
            (personAt ?p ?l) ; captain needed to be deployed on this mission
            (personAt ?e ?l) ; engineer needed at the launchbay to control the launch of the minisub
            (miniSubAt ?m ?l) ; minisub at the launchbay, must be an exploration sub
            (subAt ?s ?d) ; main submarine must be at the abyssal region too, to deploy the mini sub 
        )
    :effect 
        (and 
            (baseSubNoSecurityDeployed ?m) ; exploration sub has now been deployed 
            (not(personAt ?p ?l)) ; captain is no longer at the launchbay
            (personAt ?p ?d) ; captain is at the abyssal
            (not(miniSubAt ?m ?l)) ; exploration sub is no longer at the launchbay
            (miniSubAt ?m ?d) ; exploration sub is at the abyssal
        )
)




; MISSION SECTION
; this section is for making actions that complete missions once personnel have been deployed



;action for retrieving minerals from a ridge
(:action retrieveminerals
    :parameters 
        (?d - drillsub ?r - ridge ?l - launchbay ?x - drillreport ?m - mineral ?i - scientist ?z - section ?s - mainsub)
    :precondition 
        (and 
            (subAt ?s ?r) ; main submarine must be at the abyssal region too, to recieve the drill sub and the minerals
            (drillSubDeployed ?d) ; checking that a drill sub has been deployed
            (miniSubAt ?d ?r) ; checking that the mini sub is at the ridge region
            (mineralsAt ?m ?r) ; checking that minerals are at the region
            (personAt ?i ?l) ; checking that a science officer is at the launchbay to collect and move the minerals
            (path ?z ?l)
            
        )
    :effect 
        (and 
            (mineralsRetrieved ?m) ; minerals have now been retrieved
            (not(mineralsAt ?m ?r)) ; minerals are no longer at the ridge
            (mineralsAt ?m ?l) ; minerals are at the launchbay
            (not(miniSubAt ?d ?r)) ; drill sub no longer at the ridge
            (miniSubAt ?d ?l) ; drill sub at the launchbay
        )
)

;action for installing the sensors
(:action installsenor
    :parameters 
        (?m - expsub ?a - abyssal ?l - launchbay ?x - sensorreport  ?e - engineer ?s - mainsub)
    :precondition 
        (and 
            (sensorsNeeded ?a) ; checking that sensors are needed at an abyssal plain
            (subAt ?s ?a) ; checking that the main submarine is at the abyssal ready to receive the engineer and the exploration sub
            (sensorSubDeployed ?m) ; checking that an exploration sub has been deployed
            (miniSubAt ?m ?a) ; checking that the mini sub is at the abyssal region
        )
    :effect 
        (and 
            (sensorsSetup) ; sensors have now been setup
            (reportGenerated ?x) ; a report has been generated
            (not (miniSubAt ?m ?a)) ; exploration sub no longer at the abyssal
            (miniSubAt ?m ?l) ; exploration sub at the launchbay
            (not (personAt ?e ?a)) ; engineer is no longer at the abyssal
            (personAt ?e ?l) ; engineer is at the launchbay
        )

)

; action for checking the base, where security is deployed too
(:action basecheck
    :parameters 
        (?m - expsub ?a - abyssal ?l - launchbay ?x - basereport ?c - captain ?p - security ?b - base ?s - mainsub)
    :precondition 
        (and 
            (subAt ?s ?a) ; checking that the main submarine is at the abyssal ready to recieve the personnel and the exploration sub
            (baseSubDeployed ?m) ; checking that an exploration sub has been deployed
            (miniSubAt ?m ?a) ; checking that the mini sub is at the abyssal region
            (baseAt ?a) ; checking that there is a base at the abyssal plain
        )
    :effect 
        (and 
            (reportGenerated ?x) ; a report has been generated
            (leadersMet ?b) ; leaders have now been met
            (not (miniSubAt ?m ?a)) ; exploration sub no longer at the abyssal
            (miniSubAt ?m ?l) ; exploration sub at the launchbay
            (not (personAt ?c ?a)) ; captain is no longer at the abyssal
            (personAt ?c ?l) ; captain is at the launchbay
            (not (personAt ?p ?a)) ; security no longer at the abyssal
            (personAt ?p ?l) ; security is at the launchbay
        )
)

; this action does the exact same as the one above, however it is without security
; because of my design, this means that the base has been taken over and the captain will be injured
(:action basechecknosecurity
    :parameters 
        (?m - expsub ?a - abyssal ?l - launchbay ?x - basereport ?c - captain ?b - base ?s - mainsub)
    :precondition 
        (and
            (subAt ?s ?a)
            (baseSubNoSecurityDeployed ?m)
            (miniSubAt ?m ?a)
            (baseAt ?a)
            (atlanteanTakeover ?b) ; base has been taken over by atlanteans
        )
    :effect 
        (and
            (injured ?c) ; captain is now injured
            (reportGenerated ?x)
            (not (miniSubAt ?m ?a))
            (miniSubAt ?m ?l)
            (not (personAt ?c ?a))
            (personAt ?c ?l)
        )
)

;action for healing injured crew members
(:action healing
    :parameters 
        (?d - doctor ?p - person ?x - section ?s - sickbay)
    :precondition 
        (and 
            (personAt ?d ?s) ; a doctor must be at the sickbay
            (personAt ?p ?s) ; the person to be healed must be at the sickbay
            (injured ?p) ; the person must be injured
            (path ?x ?s)
        )
    :effect 
        (and 
            (not (injured ?p)) ; person is no longer injured
        )
)

; action for moving minerals around the submarine
; looking at the retrieveminerals action above, the scientist must already be at the launchbay, ready to collect the minerals
; since the scientist is at the launchbay, they automatically are now holding the minerals by my design
; the scientist will then move to the science lab, and the minerals will be moved to it too
(:action moveminerals
    :parameters 
        (?s - scientist ?m - mineral ?l - launchbay ?i - sciencelab ?x - drillreport ?y - section)
    :precondition 
        (and 
            (mineralsRetrieved ?m) ; minerals must have been retrieved first
            (personAt ?s ?i) ; only a science officer can move minerals, they must be at the science lab too
            (path ?y ?i)
            (mineralsAt ?m ?l) ; minerals sohuld be at the launchbay
        )
    :effect 
        (and 
            (not (mineralsAt ?m ?l)) ; since the scientist has collected them, they are no longer at the launchbay
            (mineralsAt ?m ?i) ; minerals are now at the science lab
            (reportGenerated ?x) ; a report has been generated
        )
)




; VORTEX SECTION
; section for the vortex missions



; action for initially entering a vortex
(:action entervortex
    :parameters 
        (?s - mainsub ?x - location ?v - vortex ?i - scientist ?e - engineer ?y - sciencelab ?b - bridge ?u - section ?a - active)
    :precondition 
        (and
            (personAt ?i ?y) ; scientist must be at a science lab to scan the vortex
            (personAt ?e ?b) ; an engineer must be at the bridge to activate the shields
            (subAt ?s ?v) ; submarine must go to the vortex
            (map ?x ?v)
            (path ?u ?y)
            (shieldStatus ?a) ; the shield is now set as active
            
        )
    :effect 
        (and 
            (vortexScanned ?v) ; vortex has been scanned
            (not(subAt ?s ?x)) ; submarine is no longer at its original location
            (subAt ?s ?v) ; submarine is at the vortex
        )
)

; this action is exactly the same as the one above, however the shields are down
(:action entervortexnoshield
    :parameters 
        (?s - mainsub ?x - location ?v - vortex ?i - scientist ?y - sciencelab ?u - section ?b - section ?e - engineer ?a - down)
    :precondition 
        (and
            (personAt ?i ?y)
            (personAt ?e ?b)
            (subAt ?s ?v)
            (map ?x ?v)
            (path ?u ?y)
            (shieldStatus ?a) ; the shield is now set as down, because an engineer is not present to control the shields
            
        )
    :effect 
        (and 
            (vortexScanned ?v)
            (not(subAt ?s ?x))
            (subAt ?s ?v)
        )
)

; action for what happens once a vortex is entered, when the shield is active
(:action vortexentered
    :parameters
        (?s - mainsub ?v - vortex ?x - abyssal ?r - vortexreport ?a - active)    
    :precondition
        (and
            (shieldStatus ?a) ; shield must be active
            (vortexScanned ?v) ; vortex must have been scanned
        )
    :effect
        (and
            (not(subAt ?s ?v)) ; submarine is no longer at the vortex
            (subAt ?s ?x) ; submarine is automatically teleported to an abyssal plain
            (reportGenerated ?r) ; a report has been generated
        )
)

; exactly the same as the action above, however the shield is down so the submarine will be destroyed and the mission will end
(:action vortexenterednoshield
    :parameters
        (?s - mainsub ?v - vortex ?x - ridge ?r - vortexreport ?d - down)    
    :precondition
        (and
            (shieldStatus ?d) ; shield must be down
            (vortexScanned ?v)
        )
    :effect
        (and
            (not(subAt ?s ?v))
            (subAt ?s ?x) ; submarine is at a ridge instead
            (missionCompleted)
        )
)


; FINAL section
; this section makes sure that reports are all generated and the submarine can then go back to the port


; final action for completing an entire mission set
(:action missioncomplete
    :parameters
        (?t - drillreport ?u - basereport ?v - sensorreport ?w - vortexreport ?y - militaryreport ?s - mainsub ?p - port ?x - location ?z - captain)
    :precondition
        (and
            (not(injured ?z)) ; personnel must not be injured before completion
            
            ; reports must have been generated before completion
            (reportGenerated ?t) 
            (or
            (reportGenerated ?u)             
            (reportGenerated ?y)    ; either a military report or a base report required for completion, additional feature explained below
            )
            (reportGenerated ?v)
            (reportGenerated ?w)
            (subAt ?s ?p)
            (map ?x ?p)
        )
    :effect
        (and
            (missionCompleted) ; mission is now labelled as complete
        )
)



; ADDITIONAL FEATURE SECTION 
; the feature I decided to add was an attack action, where a base can be captured if military and security are present on the mission.


; once it lands on the abyssal plain, the base gets attacked to get rid of the atlanteans and the base is now set as captured.
(:action minideployedattack
    :parameters
        (?m - militarysub ?e - engineerc ?l - launchbay ?c - location ?a - abyssal ?s - mainsub ?p - military ?q - security)
    :precondition
        (and
            
            (personAt ?p ?l) ; military needed to be deployed on this mission
            (personAt ?q ?l) ; security needed to be deployed on this mission
            (personAt ?e ?l) ; engineer needed at the launchbay to control the launch of the minisub
            (miniSubAt ?m ?l) ; minisub at the launchbay, must be an exploration sub
            (subAt ?s ?a) ; main submarine must be at the abyssal region too, to deploy the mini sub  
        )
    :effect
        (and
            (militarySubDeployed ?m) ; military sub has now been deployed 
            (not(miniSubAt ?m ?l)) ; military sub is no longer at the launchbay
            (miniSubAt ?m ?a) ; military sub is at the abyssal
            (not(personAt ?p ?l)) ; military is no longer at the launchbay
            (personAt ?p ?a) ; military is at the abyssal
            (not(personAt ?q ?l)) ; security is no longer at the launchbay
            (personAt ?q ?a) ; security is at the abyssal
        )
)


(:action attack
    :parameters
        (?m - militarysub ?a - abyssal ?l - launchbay ?x - militaryreport ?c - military ?p - security ?b - base ?s - mainsub)
    :precondition
        (and
            (atlanteansAt ?b) ; atlanteans are at the base
            (militaryDeployed ?c) ; military must have been deployed
            (subAt ?s ?a) ; checking that the main submarine is at the abyssal ready to recieve the personnel and the military sub
            (militarySubDeployed ?m) ; checking that a military sub has been deployed
            (miniSubAt ?m ?a) ; checking that the mini sub is at the abyssal region
            (baseAt ?a) ; checking that there is a base at the abyssal plain
        )
    :effect
        (and
            (reportGenerated ?x) ; a report has been generated
            (baseCaptured ?b) ; base has now been successfully captured
            (not (miniSubAt ?m ?a)) ; military sub no longer at the abyssal
            (miniSubAt ?m ?l) ; military sub at the launchbay
            (not (personAt ?c ?a)) ; military is no longer at the abyssal
            (personAt ?c ?l) ; military is at the launchbay
            (not (personAt ?p ?a)) ; security no longer at the abyssal
            (personAt ?p ?l) ; security is at the launchbay
        )
)
)