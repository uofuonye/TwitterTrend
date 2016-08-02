<<<<<<< HEAD
# build-metrics-publisher-plugin

## Overview
This project is a [Jenkins](http://jenkins-ci.org/) plugin that will allow you to publish following buildtime metrics via HTTP POST to a url .
* Build status
* Unit Test Results(captures from Juint/ TestNG)
* Code coverage(captures from Clover/ Cobertura)
* RAW Changelist
* JIRA Changelist
* Artifacts uploaded

## Usage

### Create an installable artifact:
* git clone https://github.intuit.com/ctgdevops/buildtime-metrics-publisher-plugin.git
* cd buildtime-metrics-publisher-plugin
* mvn clean install

### Upload to jenkins
* Manage Jenkins > Plugins > Advanced > Upload ./target/buildtime-metrics-publisher-plugin.hpi
* Restart Jenkins ([$JENKINS_URL]/restart)

### Setup
* Manage Jenkins > Configure System > Build metrics HTTP POST to an URL. Add credentials to make POST call.
* As part of your job: Add post-build step for Buildtime metrics and add HTTP POST URL. Headers are optional. 

Example :

Posting to artifacts-service

URL : https://artifacts-prod-us-west-2.cgdo.prod.a.intuit.com:443/artifacts-service/rest/v1/api/artifacts/properties

Following headers are added by plugin:

Build-URL & Build-Timestamp
=======
# venafi
venafi is a Ruby interface to Venafi Encryption Director. It supports most every feature that the web API supports, including:

  - Certificates
  - Config
  - configSchema
  - Credentials
  - Crypto
  - Identity
  - Log
  - Metadata
  - SecretStore
  - Workflow
  - More!

### Version
0.0.1

### Installation
```sh
$ gem install venafi
```

### Dependencies
venafi requires the following gems:
  - net/https
  - json

### Usage
All you need is your CORP credentials. Supply them in a safe manner! The constructor looks like this:
```sh
venafi = Venafi.new({
    "username" => "CORPUSERNAME"
    "password" => "CORPPASSWORD"
})
```
### Examples
Retrieve a certificate.
```sh
venafi.certificates_retrieve({
	"dn" => "\\VED\\Policy\\Foo\\Bar\\www.mydomain.com",
	"format" => "Base64",
	"include_chain" => "true",
	"include_private_key" => "true",
	"password" => "abc123"
})
```

List objects for a given DN.
```sh
venafi.config_enumerate({
	"dn" => "\\VED\\Policy\\Foo\\Bar\\"
})
```

### Getting Status and Results
There are three special methods: success, output, errors. The success method will return 1 on success or nil on failure. output will return output JSON and errors will return a semicolon-delimited list of error messages. In this example I did not include a dn when retrieving a certificate.
```sh
venafi.certificates_retrieve({
    "format" => "Base64",
    "include_chain" => "true",
    "include_private_key" => "true",
    "password" => "abc123",
})

pp venafi.success == 1 ? venafi.output : venafi.errors
```
The output will tell me so.
```sh
[gdanko@dolemite ~]$ ./vtest.rb
the following required "certificates_retrieve" options are missing: dn.
```

### Available Methods
The following methods are currently supported. Please consult the API documentation for specifics.
```sh
certificates_request
certificates_retrieve
certificates_renew
certificates_revoke
config_containable_classes
config_create
config_default_dn
config_delete
config_dn_to_guid
config_enumerate
config_enumerate_all
config_enumerate_objects_derived_from
config_enumerate_policies
config_find
config_find_containers
config_find_objects_of_class
config_find_policy
config_get_highest_revision
config_get_revision
config_guid_to_dn
config_is_valid
config_mutate_object
config_read_all
config_rename_object
config_add_value
config_add_dn_value
config_add_policy_value
config_clear_attribute
config_clear_policy_attribute
config_read
config_read_dn
config_read_dn_references
config_read_effective_policy
config_read_policy
config_remove_attribute_values
config_remove_value
config_remove_dn_value
config_remove_policy_value
config_write
config_write_dn
config_write_policy
schema_attribute
schema_attributes
schema_class
schema_classes
schema_containable_classes
credentials_create
credentials_delete
credentials_enumerate
credentials_rename
credentials_retrieve
credentials_update
credentials_delete_container
credentials_rename_container
crypto_available_keys
crypto_default_key
identity_browse
identity_get_associated_entries
identity_get_members
identity_get_memberships
identity_read_attribute
identity_self
identity_validate
log
metadata_define_item
metadata_find
metadata_find_item
metadata_get
metadata_get_item_guids
metadata_get_items
metadata_get_items_for_class
metadata_get_policy_items
metadata_items
metadata_load_item
metadata_load_item_guid
metadata_read_effective_values
metadata_read_policy
metadata_set
metadata_set_policy
metadata_undefine_item
metadata_update_item
secretstore_add
secretstore_associate
secretstore_delete
secretstore_dissociate
secretstore_encryption_keys_in_use
secretstore_lookup
secretstore_lookup_by_vault_type
secretstore_lookup_by_association
secretstore_lookup_by_owner
secretstore_mutate
secretstore_orphan_lookup
secretstore_owner_add
secretstore_owner_delete
secretstore_owner_lookup
secretstore_retrieve
workflow_ticket_create
workflow_ticket_delete
workflow_ticket_details
workflow_ticket_enumerate
workflow_ticket_exists
workflow_ticket_status
workflow_ticket_update_status
```
>>>>>>> e2c6637fdde52ff7f644d3f67507ba44658dc9f3
