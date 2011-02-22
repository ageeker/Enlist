<cfcomponent extends="MachII.framework.Plugin" depends="securityManager">

	<cffunction name="configure" returntype="void" access="public" output="false">
		<cfset var log = getLog()/>
		<cfset var sm = getSecurityManager()/>
		<cfset var sr = getParameter("securityRules", arrayNew(1))/>

		<cfset log.info("Loading security rules.")/>
		<cfset sm.load(sr, getEnvironment())/>
		<cfset log.info("The security plugin is configured with #arrayLen(sr)# rules.")/>
	</cffunction>

	<cffunction name="preProcess" returntype="void" access="public" output="false">
		<cfargument name="eventContext" type="MachII.framework.eventContext" required="yes"/>

		<cfset var event = ""/>
		<cfset var log = getLog()/>
		<cfset var authentication = "null"/>
		<cfset var authorization = "null"/>
		<cfset var environment = getEnvironment()/>
		<cfset var securityManager = getSecurityManager()/>
		<cfset var sessionFacade = getProperty("sessionFacade")/>
		<cfset var result = structNew()/>
		<cfset var args = structNew()/>

		<cfset result.success = false/>
		<cfset result.message = ""/>

		<!---
		If Mach-II has no event, there's no event name on which to judge authorization
		--->
		<cfif arguments.eventContext.hasNextEvent()>
			<cfset event = arguments.eventContext.getNextEvent()/>
			<cfif log.isInfoEnabled()>
				<cfset log.info("Event name: " & event.getName())/>
			</cfif>
		<cfelse>
			<cfif log.isInfoEnabled()>
				<cfset log.info("No event; exiting")/>
			</cfif>
			<cfreturn/>
		</cfif>

		<!---
		The side-effect of the plugin is that the session facade always has an authentication object.
		--->
		<cfif sessionFacade.isPropertyDefined("authentication")>
			<cfset authentication = sessionFacade.getProperty("authentication")/>
			<cfif log.isDebugEnabled()>
				<cfset log.debug("Session facade contains authentication: #authentication.getSummary()#")/>
			</cfif>
		<cfelse>
			<cfif log.isDebugEnabled()>
				<cfset log.debug("No authentication in session facade; Creating anonymous authentication")/>
			</cfif>
			<cfset authentication = securityManager.getAuthenticationService().create()/>
			<cfset sessionFacade.setProperty("authentication", authentication)/>
		</cfif>

		<!---
		Request authorization for the current event and the authentication object, which will contain the name of the event on which to apply security rules.
		--->
		<cfset authorization = securityManager.getAuthorizationService().create(authentication)/>
		<cfset authorization.setEventName(event.getName())/>
		<cfset securityManager.getAuthorizationService().authorize(authorization)/>
		<cfif log.isDebugEnabled()>
			<cfset log.debug("Authorization complete: #authorization.getSummary()#")/>
		</cfif>

		<cfif authorization.hasMatchedSecurityRule()>
			<cfif log.isInfoEnabled()>
				<cfset log.info("Authorization matched security rule: #authorization.getMatchedSecurityRule().getSummary()#")/>
			</cfif>
		<cfelse>
			<cfif log.isWarnEnabled()>
				<cfset log.warn("Authorization did not match security rules.")/>
			</cfif>
		</cfif>

		<cfif authorization.getIsAuthorized()>
			<cfif log.isInfoEnabled()>
				<cfset log.info("Authorization result: access granted")/>
			</cfif>
		<cfelseif authorization.getAuthenticationRequired()>
			<cfif log.isInfoEnabled()>
				<cfset log.info("Authorization result: authentication required")/>
			</cfif>
			<cfset result.message = getParameter("authenticationRequiredMessage")/>
			<cfset args.result = result/>
			<cfset event.setArg("result", result)/>
			<cfset arguments.eventContext.clearEventQueue()/>
			<cfset arguments.eventContext.announceEvent(getParameter("authenticationRequiredEvent"), args)/>
		<cfelse>
			<cfif log.isInfoEnabled()>
				<cfset log.info("Authorization result: access denied")/>
			</cfif>
			<cfset result.message = getParameter("authorizationFailedMessage")/>
			<cfset args.result = result/>
			<cfset arguments.eventContext.clearEventQueue()/>
			<cfset arguments.eventContext.announceEvent(getParameter("authorizationFailedEvent"), args)/>
		</cfif>
	</cffunction>

	<cffunction name="getEnvironment" returntype="struct" access="private" output="false">
		<cfset var environment = structNew()/>

		<cfset environment.group = getAppManager().getEnvironmentGroup()/>
		<cfset environment.name = getAppManager().getEnvironmentName()/>
		<cfreturn environment/>
	</cffunction>

</cfcomponent>