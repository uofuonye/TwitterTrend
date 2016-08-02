require "net/https"
require "json"

class Venafi
	attr_accessor :_api_key
	attr_accessor :_success
	attr_accessor :_output
	attr_accessor :_count
	attr_accessor :_errors
	attr_accessor :_debug
	attr_accessor :_urls
	attr_accessor :_token
	attr_accessor :proxy
	attr_accessor :base_url

	def initialize(opts)
		self._urls = Array.new
		self._errors = Array.new
		self.base_url = "https://venafi.intuit.com/vedsdk"
		if (opts["username"] == nil || opts["username"].length < 1)
			self._error_exit("you must specify your corp username in the constructor.")
		end

		if (opts["password"] == nil || opts["password"].length < 1)
			self._error_exit("you must specify your corp password in the constructor.")
		end
		self._api_key = self._get_api_key(opts["username"], opts["password"])
	end

	def debug(flag)
		return unless flag
		if (flag == "on")
			flag = "on"
		else
			flag = "off"
		end
		self._debug = flag
	end

	def success
		return self._success || nil
	end

	def count
		return self._count || 0
	end

	def last_url
		return self._urls[ self._urls.length - 1] || nil
	end

	def output
		return self._output
	end

	def errors
		return self._errors.join("; ") || nil
	end

	def _debug_text(text)
		return unless self._debug == "on"
		puts("[Debug] #{text}")
	end

	def _error_exit(text)
		puts("[Error] #{text}")
		exit
	end

	def _warn_text(text)
		puts("[Warn] #{text}")
	end

	def _get_api_key(username, password)
		content = self._venafi_request(
			"post",
			"authorize/",
			{ "Username" => username, "Password" => password },
		)

		if (self.success)
			if (defined?(content["APIKey"]))
				return content["APIKey"]
			end
		else
			self._error_exit(sprintf("failed to obtain an api key: %s", self.errors))
		end
	end

	def _validate_json(string)
		hashref = JSON.parse(string)
		return hashref
	rescue JSON::ParserError
		return nil
	end

	def certificates_request(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w()
		if ((required - opts.keys).length == 0)
			content["PolicyDN"] = opts["policy_dn"] if opts["policy_dn"]
			content["CADN"] = opts["ca_dn"] if opts["ca_dn"]
			content["ObjectName"] = opts["object_name"] if opts["object_name"]
			content["PKCS10"] = opts["pkcs10"] if opts["pkcs10"]
			content["Subject"] = opts["subject"] if opts["subject"]
			content["OrganizationalUnit"] = opts["ou"] if opts["ou"]
			content["Organization"] = opts["org"] if opts["org"]
			content["City"] = opts["city"] if opts["city"]
			content["State"] = opts["state"] if opts["state"]
			content["Country"] = opts["country"] if opts["country"]
			content["KeyBitSize"] = opts["bits"] if opts["bits"]
			content["CASpecificAttributes"] = opts["ca_specific_attributes"] if opts["ca_specific_attributes"]
			content["SubjectAltNames"] = opts["subject_alt_names"] if opts["subject_alt_names"]
			#content["DisableAutomaticRenewal"] = opts["city"] if opts["city"]
			self._venafi_request(
				"post",
				"Certificates/Request",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def certificates_retrieve(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn format)
		if ((required - opts.keys).length == 0)
			# Formats:
			# Base64: Regular PEM file (“traditional” file format)
			# Base64 (PKCS #8): PEM file with PKCS#8 encoded private key
			# DER: Raw certificate
			# PKCS #7: Certificate with optional chain
			# PKCS #12: Certificate and private key
			content["CertificateDN"] = opts["dn"]
			content["Format"] = opts["format"]
			content["IncludeChain"] = opts["include_chain"] if opts["include_chain"]
			content["IncludePrivateKey"] = opts["include_private_key"] if opts["include_private_key"]
			content["FriendlyName"] = opts["friendly_name"] if opts["friendly_name"]
			if (opts["include_private_key"])
				if (opts["password"])
					content["Password"] = opts["password"]
				else
					self._success = nil
					self._errors.push(sprintf("the include_private_key option requires the passphrase options."))
				end
			end
			if (self.success)
				self._venafi_request(
					"post",
					"Certificates/Retrieve",
					content
				)
			end
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def certificates_renew(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["CertificateDN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Certificates/Renew",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def certificates_revoke(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["CertificateDN"] = opts["dn"]
			content["Thumbprint"] = opts["thumbprint"] if opts["thumbprint"]
			# Reasons 0-5 page 59 in docs
			content["Reason"] = opts["reason"] if opts["reason"]
			content["Comments"] = opts["comments"] if opts["comments"]
			content["Disabled"] = defined?(opts["disabled"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Certificates/Revoke",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_containable_classes(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w()
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["object_dn"] if opts["object_dn"]
			self._venafi_request(
				"post",
				"Config/ContainableClasses",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_create(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn class)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Class"] = opts["class"]
			content["NameAttributesList"] = opts["name_attributes_list"] if opts["name_attributes_list"] # Array of hashes
			self._venafi_request(
				"post",
				"Config/Create",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_default_dn(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"Config/DefaultDn",
			content
		)
	end

	def config_delete(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Recursive"] = defined?(opts["recursive"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Config/Delete",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_dn_to_guid(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Config/DnToGuid",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_enumerate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Recursive"] = "true" if opts["recursive"]
			content["Pattern"] = opts["pattern"] if opts["pattern"]
			self._venafi_request(
				"post",
				"Config/Enumerate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_enumerate_all(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(pattern)
		if ((required - opts.keys).length == 0)
			content["Pattern"] = opts["pattern"]
			self._venafi_request(
				"post",
				"Config/EnumerateAll",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_enumerate_objects_derived_from(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(derived_from)
		if ((required - opts.keys).length == 0)
			content["DerivedFrom"] = opts["derived_from"]
			content["Pattern"] = opts["pattern"] if opts["pattern"]
			self._venafi_request(
				"post",
				"Config/EnumerateObjectsDerivedFrom",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_enumerate_policies(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Config/EnumeratePolicies",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_find(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(pattern)
		if ((required - opts.keys).length == 0)
			content["Pattern"] = opts["pattern"]
			content["AttributeNames"] = opts["attribute_names"] if opts["attribute_names"] # Array of hashes
			self._venafi_request(
				"post",
				"Config/Find",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_find_containers(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(pattern)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Recursive"] = defined?(opts["recursive"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Config/FindContainers",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_find_objects_of_class(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(classes class)
		# Figure out OR stuff
		if (opts["classes"] || opts["class"])
			content["Classes"] = opts["classes"] if opts["classes"]
			content["Class"] = opts["class"] if opts["class"]
			content["Pattern"] = opts["pattern"] if opts["pattern"]
			content["ObjectDN"] = opts["dn"] if opts["dn"]
			content["Recursive"] = defined?(opts["recursive"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Config/FindObjectsOfClass",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the \"%s\" method requires one of the following options: %s.", __method__, required.join(", ")))
		end
	end

	def config_find_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn class attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Class"] = opts["class"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/FindPolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_get_highest_revision(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Classes"] = opts["classes"] if opts["classes"]
			self._venafi_request(
				"post",
				"Config/GetHighestRevision",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_get_revision(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Config/GetRevision",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_guid_to_dn(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid)
		if ((required - opts.keys).length == 0)
			content["ObjectGUID"] = opts["guid"]
			self._venafi_request(
				"post",
				"Config/GuidToDn",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_is_valid(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn guid)
		# Figure out OR stuff
		if (opts["dn"] || opts["guid"])
			content["ObjectDN"] = opts["dn"] if opts["dn"]
			content["ObjectGUID"] = opts["guid"] if opts["guid"]
			self._venafi_request(
				"post",
				"Config/IsValid",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the \"%s\" method requires one of the following options: %s.", __method__, required.join(", ")))
		end
	end

	def config_mutate_object(*args)
		# Check this one out, it could be dangerous
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
	end

	def config_read_all(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Config/ReadAll",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_rename_object(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn new_dn)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["NewObjectDN"] = opts["new_dn"]
			self._venafi_request(
				"post",
				"Config/RenameObject",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_add_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Value"] = opts["value"]
			self._venafi_request(
				"post",
				"Config/AddValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_add_dn_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Value"] = opts["value"]
			self._venafi_request(
				"post",
				"Config/AddDnValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_add_policy_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Class"] = opts["class"] if opts["class"]
			content["Value"] = opts["value"]
			content["Locked"] = defined?(opts["locked"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Config/AddPolicyValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_clear_attribute(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/ClearAttribute",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_clear_policy_attribute(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn class attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"] if opts["dn"]
			content["Class"] = opts["class"] if opts["class"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/ClearPolicyAttribute",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_read(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/Read",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_read_dn(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/ReadDn",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_read_dn_references(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn reference_attribute_name attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["ReferenceAttributeName"] = opts["reference_attribute_name"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/ReadDnReferences",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_read_effective_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Config/ReadEffectivePolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_read_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name class)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Class"] = opts["class"]
			self._venafi_request(
				"post",
				"Config/ReadPolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_remove_attribute_values(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(pattern)
		if ((required - opts.keys).length == 0)
			content["Pattern"] = opts["pattern"]
			self._venafi_request(
				"post",
				"Config/RemoveAttributeValues",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_remove_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Value"] = opts["value"]
			self._venafi_request(
				"post",
				"Config/RemoveValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_remove_dn_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Value"] = opts["value"]
			self._venafi_request(
				"post",
				"Config/RemoveDnValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_remove_policy_value(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name class value)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Class"] = opts["class"]
			content["Value"] = opts["value"]
			self._venafi_request(
				"post",
				"Config/RemovePolicyValue",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_write(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name values)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Values"] = opts["values"] # Array
			self._venafi_request(
				"post",
				"Config/Write",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_write_dn(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn attribute_name values)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["AttributeName"] = opts["attribute_name"]
			content["Values"] = opts["values"] # Array
			self._venafi_request(
				"post",
				"Config/WriteDn",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def config_write_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn class attribute values)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Class"] = opts["class"]
			content["Attribute"] = opts["attribute"]
			content["Locked"] = defined?(opts["locked"]) ? "true" : "false"
			content["Values"] = opts["values"] # Array
			self._venafi_request(
				"post",
				"Config/WritePolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	# POST configSchema/* Stuff - No examples
	def schema_attribute(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(attribute_name)
		if ((required - opts.keys).length == 0)
			content["Attribute"] = opts["attribute"]
			self._venafi_request(
				"post",
				"configSchema/Attribute",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def schema_attributes(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w()
		if ((required - opts.keys).length == 0)
			self._venafi_request(
				"post",
				"configSchema/Attributes",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def schema_class(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(class)
		if ((required - opts.keys).length == 0)
			content["Class"] = opts["class"]
			self._venafi_request(
				"post",
				"configSchema/Class",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def schema_classes(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(derived_from)
		if ((required - opts.keys).length == 0)
			content["DerivedFrom"] = opts["derived_from"]
			self._venafi_request(
				"post",
				"configSchema/Classes",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def schema_containable_classes(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(class)
		if ((required - opts.keys).length == 0)
			content["Class"] = opts["class"]
			self._venafi_request(
				"post",
				"configSchema/ContainableClasses",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_create(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path friendly_name values)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["FriendlyName"] = opts["friendly_name"]
			content["Values"] = opts["values"] # Array of hashes
			content["Contact"] = opts["contact"] if opts["contact"] # Array
			content["EncryptionKey"] = opts["encryption_key"] if opts["encryption_key"]
			content["Expiration"] = opts["expiration"] if opts["expiration"] # Unix Time		
			content["Shared"] = defined?(opts["shared"]) ? "true" : "false"
			content["Description"] = opts["description"] if opts["description"]
			self._venafi_request(
				"post",
				"Credentials/Create",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_delete(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			self._venafi_request(
				"post",
				"Credentials/Delete",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_enumerate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["Pattern"] = opts["pattern"] if opts["pattern"]
			content["Recursive"] = defined?(opts["recursive"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Credentials/Enumerate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_rename(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path new_credential_path)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["NewCredentialPath"] = opts["new_credential_path"]
			self._venafi_request(
				"post",
				"Credentials/Rename",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_retrieve(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path)
		if ((required - opts.keys).length == 0)
			self._venafi_request(
				"post",
				"Credentials/Retrieve",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_update(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path friendly_name values)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["FriendlyName"] = opts["friendly_name"]
			content["Values"] = opts["values"] # Array of hashes
			content["Contact"] = opts["contact"] if opts["contact"] # Array
			content["EncryptionKey"] = opts["encryption_key"] if opts["encryption_key"]
			content["Expiration"] = opts["expiration"] if opts["expiration"] # Unix Time
			content["Shared"] = defined?(opts["shared"]) ? "true" : "false"
			content["Description"] = opts["description"] if opts["description"]
			self._venafi_request(
				"post",
				"Credentials/Update",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_delete_container(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["Recursive"] = defined?(opts["recursive"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Credentials/DeleteContainer",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def credentials_rename_container(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(credential_path new_credential_path)
		if ((required - opts.keys).length == 0)
			content["CredentialPath"] = opts["credential_path"]
			content["NewCredentialPath"] = opts["new_credential_path"]
			self._venafi_request(
				"post",
				"Credentials/RenameContainer",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def crypto_available_keys(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"Crypto/AvailableKeys",
			content
		)
	end

	def crypto_default_key(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"Crypto/DefaultKey",
			content
		)
	end

	def identity_browse(*args)
		# IMPORTANT! Although all of the parameters are listed as optional, at least one parameter must be specified.
		# Specifically, IdentityType must be specified in order to obtain results for Local identities. Filter and
		# Limit must be specified in order to obtain results for non-Local (AD and LDAP) identities.
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(container filter limit identity_type)
		# Figure out OR stuff
		if (opts["container"] || opts["filter"] || opts["limit"] || opts["identity_type"])
			content["Container"] = opts["container"] if opts["container"]
			content["Filter"] = opts["filter"] if opts["filter"]
			content["Limit"] = opts["limit"] if opts["limit"]
			content["IdentityType"] = opts["identity_type"] if opts["identity_type"]
			self._venafi_request(
		   		"post",
				"Identity/Browse",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the \"%s\" method requires one of the following options: %s.", __method__, required..join(", ")))
		end
	end

	def identity_get_associated_entries(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(id)
		if ((required - opts.keys).length == 0)
			content["ID"] = opts["id"]
			# ID = { Prefix => xx, Name => xx, FullName => xx, Universal => xx, IsGroup => [true|false], IsContainer => [true|false] }
			self._venafi_request(
				"post",
				"Identity/GetAssociatedEntries",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def identity_get_members(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(id)
		if ((required - opts.keys).length == 0)
			content["ID"] = opts["id"]
			# ID = { Prefix => xx, Name => xx, FullName => xx, Universal => xx, IsGroup => [true|false], IsContainer => [true|false] }
			content["ResolveNested"] = defined?(opts["resolve_nested"]) ? 1 : 0
			self._venafi_request(
				"post",
				"Identity/GetMembers",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def identity_get_memberships(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(id)
		if ((required - opts.keys).length == 0)
			content["ID"] = opts["id"]
			# ID = { Prefix => xx, Name => xx, FullName => xx, Universal => xx, IsGroup => [true|false], IsContainer => [true|false] }
			self._venafi_request(
				"post",
				"Identity/GetMemberships",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def identity_read_attribute(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(id attribute_name)
        if ((required - opts.keys).length == 0)
			content["ID"] = opts["id"]
			# ID = { Prefix => xx, Name => xx, FullName => xx, Universal => xx, IsGroup => [true|false], IsContainer => [true|false] }
			content["AttributeName"] = opts["attribute_name"]
			self._venafi_request(
				"post",
				"Identity/ReadAttribute",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def identity_self(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"Identity/Self",
			content
		)
	end

	def identity_validate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(id)
        if ((required - opts.keys).length == 0)
			content["ID"] = opts["id"]
			# ID = { Prefix => xx, Name => xx, FullName => xx, Universal => xx, IsGroup => [true|false], IsContainer => [true|false] }
			self._venafi_request(
				"post",
				"Identity/Validate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def log(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(component id severity text1 text2 value1 value2 grouping)
		if ((required - opts.keys).length == 0)
			content["Component"] = opts["component"] 
			content["Severity"] = opts["severity"]
			content["Text1"] = opts["text1"]
			content["Text2"] = opts["text2"]
			content["Value1"] = opts["value1"]
			content["Value2"] = opts["value2"]
			content["Grouping"] = opts["grouping"]
			self._venafi_request(
				"post",
				"Log",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_define_item(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(item)
        if ((required - opts.keys).length == 0)
			content["Item"] = opts["item"]
			# item = { Label => xx, Name => xx, Classes => [ x, x, x ], Type => 1 }
			self._venafi_request(
				"post",
				"Metadata/DefineItems",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_find(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(item item_guid value)
        if ((required - opts.keys).length == 0)
			content["Item"] = opts["item"] if opts["item"]
			# item = { Label => xx, Name => xx, Classes => [ x, x, x ], Type => 1 }
			content["ItemGuid"] = opts["item_guid"] if opts["item_guid"]
			content["Value"] = opts["value"] if opts["value"]
			self._venafi_request(
				"post",
				"Metadata/Find",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_find_item(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(name)
        if ((required - opts.keys).length == 0)
			content["Name"] = opts["name"]
			self._venafi_request(
				"post",
				"Metadata/FindItem",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_get(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			content["All"] = defined?(opts["all"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Metadata/Get",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_get_item_guids(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Metadata/GetItemGuids",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_get_items(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Metadata/GetItems",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_get_items_for_class(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(config_class)
        if ((required - opts.keys).length == 0)
			content["ConfigClass"] = opts["config_class"]
			self._venafi_request(
				"post",
				"Metadata/GetItems",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_get_policy_items(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Metadata/GetPolicyItems",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_items(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"Metadata/Items",
			content
		)
	end

	def metadata_load_item(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Metadata/LoadItem",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_load_item_guid(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			self._venafi_request(
				"post",
				"Metadata/LoadItemGuid",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_read_effective_values(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn item_guid)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			content["ItemGuid"] = opts["item_guid"]
			self._venafi_request(
				"post",
				"Metadata/ReadEffectiveValues",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_read_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn item_guid type)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			content["ItemGuid"] = opts["item_guid"]
			content["Type"] = opts["type"] # Device or X509 Certificate
			self._venafi_request(
				"post",
				"Metadata/ReadPolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_set(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn guid_data)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			content["GuidData"] = opts["guid_data"] # { ItemGuid => xxxx, List => [ x, x, x ] }
			self._venafi_request(
				"post",
				"Metadata/ReadPolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_set_policy(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(dn config_class guid_data)
        if ((required - opts.keys).length == 0)
			content["DN"] = opts["dn"]
			content["ConfigClass"] = opts["config_class"]
			content["Locked"] = defined?(opts["locked"]) ? "true" : "false"
			content["GuidData"] = opts["guid_data"] # { ItemGuid => xxxx, List => [ x, x, x ] }
			self._venafi_request(
				"post",
				"Metadata/SetPolicy",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_undefine_item(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
        required = %w(item_guid)
        if ((required - opts.keys).length == 0)
			content["ItemGuid"] = opts["item_guid"]
			content["RemoveData"] = defined?(opts["remove_data"]) ? "true" : "false"
			self._venafi_request(
				"post",
				"Metadata/UndefineItem",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def metadata_update_item(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
	end

	def secretstore_add(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_type key_name base64data namespace owner)
		if ((required - opts.keys).length == 0)
			content["VaultType"] = opts["vault_type"]
			content["KeyName"] = opts["key_name"]
			content["Base64Data"] = opts["base64data"]
			content["Namespace"] = opts["namespace"]
			content["Owner"] = opts["owner"]
			self._venafi_request(
				"post",
				"SecretStore/Add",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_associate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id name)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			content["Name"] = opts["name"]
			# NOTE At least one of the optional parameters is required and only one will be honored by this call.
			content["StringValue"] = opts["string_value"] if opts["string_value"]
			content["IntValue"] = opts["int_value"] if opts["int_value"]
			content["DateValue"] = opts["date_value"] if opts["date_value"]
			self._venafi_request(
				"post",
				"SecretStore/Associate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_delete(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			self._venafi_request(
				"post",
				"SecretStore/Delete",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_dissociate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			content["Name"] = opts["name"] if opts["name"]
			content["StringValue"] = opts["string_value"] if opts["string_value"]
			content["IntValue"] = opts["int_value"] if opts["int_value"]
			content["DateValue"] = opts["date_value"] if opts["date_value"]
			self._venafi_request(
				"post",
				"SecretStore/Dissociate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_encryption_keys_in_use(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"SecretStore/EncryptionKeysInUse",
			content
		)
	end

	def secretstore_lookup(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		self._venafi_request(
			"get",
			"SecretStore/Lookup",
			content
		)
	end

	def secretstore_lookup_by_vault_type(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_type)
		if ((required - opts.keys).length == 0)
			content["VaultType"] = opts["vault_type"]
			self._venafi_request(
				"post",
				"SecretStore/LookupByVaultType",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_lookup_by_association(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(name)
		if ((required - opts.keys).length == 0)
			content["Name"] = opts["name"]
			content["StringValue"] = opts["string_value"] if opts["string_value"]
			content["IntValue"] = opts["int_value"] if opts["int_value"]
			content["DateValue"] = opts["date_value"] if opts["date_value"]
			self._venafi_request(
				"post",
				"SecretStore/LookupByAssociation",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_lookup_by_owner(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(namespace owner)
		if ((required - opts.keys).length == 0)
			content["Namespace"] = opts["namespace"]
			content["Owner"] = opts["owner"]
			content["VaultType"] = opts["vault_type"] if opts["vault_type"]
			self._venafi_request(
				"post",
				"SecretStore/LookupByOwner",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_mutate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id vault_type)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			content["VaultType"] = opts["vault_type"]
			self._venafi_request(
				"post",
				"SecretStore/Mutate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_orphan_lookup(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w()
		if ((required - opts.keys).length == 0)
			content["VaultType"] = opts["vault_type"] if opts["vault_type"]
			self._venafi_request(
				"post",
				"SecretStore/OrphanLookup",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_owner_add(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id namespace owner)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			content["Namespace"] = opts["namespace"]
			content["Owner"] = opts["owner"]
			self._venafi_request(
				"post",
				"SecretStore/OwnerAdd",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_owner_delete(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(namespace owner)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"] if opts["vault_id"]
			content["Namespace"] = opts["namespace"]
			content["Owner"] = opts["owner"]
			self._venafi_request(
				"post",
				"SecretStore/OwnerDelete",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_owner_lookup(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id namespace)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			content["Namespace"] = opts["namespace"]
			self._venafi_request(
				"post",
				"SecretStore/OwnerLookup",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def secretstore_retrieve(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(vault_id)
		if ((required - opts.keys).length == 0)
			content["VaultID"] = opts["vault_id"]
			self._venafi_request(
				"post",
				"SecretStore/Retrieve",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_create(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(dn reason)
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"]
			content["Reason"] = opts["reason"]
			content["UserData"] = opts["user_data"] if opts["user_data"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Create",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_delete(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid)
		if ((required - opts.keys).length == 0)
			content["GUID"] = opts["guid"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Delete",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_details(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid)
		if ((required - opts.keys).length == 0)
			content["GUID"] = opts["guid"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Details",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_enumerate(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w()
		if ((required - opts.keys).length == 0)
			content["ObjectDN"] = opts["dn"] if opts["dn"]
			content["UserData"] = opts["user_data"] if opts["user_data"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Enumerate",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_exists(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid)
		if ((required - opts.keys).length == 0)
			content["GUID"] = opts["guid"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Exists",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_status(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid)
		if ((required - opts.keys).length == 0)
			content["GUID"] = opts["guid"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/Status",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def workflow_ticket_update_status(*args)
		opts = args[0] || Hash.new
		content = Hash.new
		self._output = Hash.new
		required = %w(guid status)
		if ((required - opts.keys).length == 0)
			content["GUID"] = opts["guid"]
			content["Status"] = opts["status"]
			content["Explanation"] = opts["explanation"] if opts["explanation"]
			self._venafi_request(
				"post",
				"Workflow/Ticket/UpdateStatus",
				content
			)
		else
			self._success = nil
			self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
		end
	end

	def x509_certificate_store_retrieve(*args)
        opts = args[0] || Hash.new
        content = Hash.new
        self._output = Hash.new
        required = %w(vault_id)
        if ((required - opts.keys).length == 0)
            content["VaultId"] = opts["vault_id"]
            self._venafi_request(
                "post",
                "X509CertificateStore/Retrieve",
                content
            )
        else
            self._success = nil
            self._errors.push(sprintf("the following required \"%s\" options are missing: %s.", __method__, (required - opts.keys).join(", ")))
        end
    end

	def _venafi_request(http_method, uri, content)
		req = nil
		method = caller[0][/`.*'/][1..-2]
		self._debug_text(sprintf("executing method: %s", method))
		errors, message = Array.new, Array.new

		url = sprintf(
			"%s/%s?apikey=%s",
			self.base_url,
			uri,
			self._api_key || nil
		)
		enc = URI.escape(url)
		uri = URI(enc)
		http = Net::HTTP.new(uri.host, uri.port)
		payload = content.to_json if content

		if (http_method =~ /^get$/i)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			http.read_timeout = 10
			req = Net::HTTP::Get.new(uri.request_uri)

		elsif (http_method =~ /^post$/i)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			http.read_timeout = 10
			req = Net::HTTP::Post.new(uri.request_uri)
			req.body = payload if payload
		end

		req["Content-Type"] = "application/json"
		self._debug_text("fetching #{url}")
		self._debug_text("payload: #{payload}") if payload

		begin
			res = http.request(req)

			if (res.code =~ /^2\d\d$/)
				hashref = self._validate_json(res.body)
				if (hashref)
					if (hashref["Error"])
						message.push(sprintf("message=%s", hashref["Error"]))
						self._success = nil 
						self._errors.push(sprintf("method %s failed: %s", method, message.join("; ")))
					else
						self._success = 1
						self._output = hashref.clone
					end
				else
					self._success = nil
					self._errors.push(sprintf("method %s failed: invalid json received.", method))
				end
			else
				message.push(sprintf("code=%s", res.code))
				message.push(sprintf("message=%s", res.message.downcase))
				self._success = nil
				self._errors.push(sprintf("method %s failed: %s", method, message.join("; ")))
			end
		rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
			self._success = nil
			self._errors.push(sprintf("unfortunately an ugly net::http error occurred: %s", e.to_s.downcase))
		end
	end
end
