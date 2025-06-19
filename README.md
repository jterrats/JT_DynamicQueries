# JT_DynamicQueries
A Utility class that serves a data layer selector to perform dynamic queries based on configurations

<a href="https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

In order to use this configurable queries, assign the permission set JT Dynamic Queries to your user. It will allow apex / cmdt access.

## How to Implement Configurable Queries
It's straightforward! You'll need to create one record per query in the JT Dynamic Queries custom metadata type **(CMDT)**. This record includes several key fields:

*Base Query field*
This field is where you define the SOQL query you wish to execute. For example, to retrieve accounts:


`SELECT Id, Name FROM Account WHERE Name in: names`

*Binding field*
If you know the specific values to expect in your query results, use the Binding field. This field expects a JSON object. For instance:

`{"name": "John Doe"}`

Alternatively, if the values aren't known beforehand, you can leave this field blank. Your Apex code can then dynamically obtain the necessary values for the bindings. For documentation purposes, however, we'll demonstrate using a value configured directly in the Binding field.

Example using a CMDT-configured binding:
Apex

`JT_DynamicSelector.getRecord('Get_Accounts', true);`

This getRecord method takes two parameters: the record name from your CMDT and a boolean value indicating whether the query should execute in `USER ACCESS MODE` or `SYSTEM ACCESS MODE`.

In case you want to pass bindings programatically, by using method overloading you can pass them from your apex code.

`JT_DynamicSelector.getRecord('Get_Accounts', true, myBindings)`

Where my bindings follow the **Map** structure in **APEX** {'name'=>'John Doe'}

<a href="https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
