<!---

    Enlist - Volunteer Management Software
    Copyright (C) 2011 GreatBizTools, LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.

$Id: $

Notes:
--->
<cfcomponent
	displayname="UserService"
	output="false">

	<!---
	PROPERTIES
	--->
	<cfset variables.googleUserService = "" />
	<cfset variables.userGateway = "" />
	<cfset variables.sessionFacade = "" />

	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="UserService" output="false"
		hint="Initializes the service.">

		<cfset var googleUserFactory = CreateObject("java", "com.google.appengine.api.users.UserServiceFactory") />

		<cfset variables.googleUserService = googleUserFactory.getUserService() />

		<cfreturn this />
	</cffunction>

	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="getUser" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" />
		<cfreturn getUserGateway().read( arguments.id ) />
	</cffunction>

	<cffunction name="getUsers" access="public" returntype="array" output="false">
		<cfreturn getUserGateway().list() />
	</cffunction>

	<cffunction name="getUsersByRole" access="public" returntype="array" output="false">
		<cfargument name="role" type="string" required="true" />
		<cfreturn getUserGateway().getUsersByRole( arguments.role ) />
	</cffunction>

	<cffunction name="getUsersBySearch" access="public" returntype="array" output="false">
		<cfargument name="id" type="string" required="false" default="" />
		<cfargument name="status" type="string" required="false" default="" />
		<cfargument name="role" type="string" required="false" default="" />
		<cfargument name="chapterId" type="string" required="false" default="" />
		<cfargument name="firstName" type="string" required="false" default="" />
		<cfargument name="lastName" type="string" required="false" default="" />
		<cfargument name="googleEmail" type="string" required="false" default="" />
		<cfargument name="altEmail" type="string" required="false" default="" />
		<cfreturn getUserGateway().listByPropertyMap( arguments ) />
	</cffunction>

	<cffunction name="getUserByGoogleEmail" access="public" returntype="any" output="false"
		hint="Gets an User from the datastore by Google Email.">
		<cfargument name="googleEmail" type="string" required="true" />
		<cfreturn getUserGateway().readByProperty( "googleEmail", arguments.googleEmail ) />
	</cffunction>

	<cffunction name="logoutUser" access="public" returntype="void" output="false">
		<cfargument name="user" type="Enlist.model.user.User" required="true">
		<cfset variables.sessionFacade.removeUser() />
	</cffunction>

	<cffunction name="registerUser" access="public" returntype="void" output="false">
		<cfargument name="user" type="Enlist.model.user.User" required="true">
		<cfset saveUser( arguments.user )>
		<cfset variables.sessionFacade.setUser( arguments.user )>
	</cffunction>

	<cffunction name="saveUser" access="public" returntype="void" output="false">
		<cfargument name="user" type="Enlist.model.user.User" required="true">
		<cfif not len( arguments.user.getGoogleEmail() )>
			<cfif not variables.googleUserService.isUserLoggedIn()>
				<cfthrow message="Unable to save user without googleEmail." />
			</cfif>
			<cfset arguments.user.setGoogleEmail( variables.googleUserService.getCurrentUser().getEmail() ) />
		</cfif>
		<cfset getUserGateway().save( arguments.user ) />
		<cfset variables.sessionFacade.setUser( arguments.user )>
	</cffunction>

	<!---
	ACCESSORS
	--->
	<cffunction name="getGoogleUserService" access="public" returntype="any" output="false">
		<cfreturn variables.googleUserService />
	</cffunction>
	<cffunction name="setGoogleUserService" access="public" returntype="void" output="false">
		<cfargument name="googleUserService" type="any" required="true" />
		<cfset variables.googleUserService = arguments.googleUserService />
	</cffunction>

	<cffunction name="getSessionFacade" access="public" returntype="SessionFacade" output="false">
		<cfreturn variables.sessionFacade />
	</cffunction>
	<cffunction name="setSessionFacade" access="public" returntype="SessionFacade" output="false">
		<cfargument name="sessionFacade" type="any" required="true" />
		<cfset variables.sessionFacade = arguments.sessionFacade />
	</cffunction>

	<cffunction name="getUserGateway" access="public" returntype="any" output="false">
		<cfreturn variables.userGateway />
	</cffunction>
	<cffunction name="setUserGateway" access="public" returntype="void" output="false">
		<cfargument name="userGateway" type="any" required="true" />
		<cfset variables.userGateway = arguments.userGateway />
	</cffunction>

</cfcomponent>