package com.intuit.ctg.devops.jenkinsplugins;


import net.sf.json.JSONObject;

import org.kohsuke.stapler.StaplerRequest;

import hudson.Extension;
import hudson.model.AbstractProject;
import hudson.tasks.BuildStepDescriptor;
import hudson.tasks.Publisher;

@Extension
public final class DescriptorImpl extends BuildStepDescriptor<Publisher> {
	
	private String username;
	private String password;
	private String proxyPort;
	private String proxyHost;

	public boolean configure() {
		save();
		return true;
	}
   
    public DescriptorImpl() {
		super(BuildMetricsPublisher.class);

		load();
	}
    
	@SuppressWarnings("rawtypes")
    @Override
    public boolean isApplicable(Class<? extends AbstractProject> jobType) {
      return true;
    }

    @Override
    public String getDisplayName() {
      return "Build metrics HTTP POST to an URL";
    }

	@Override
	public boolean configure(StaplerRequest req, JSONObject json)
			throws hudson.model.Descriptor.FormException {
		username = json.getString("username");
		password = json.getString("password");
		proxyPort = json.getString("proxyPort");
		proxyHost = json.getString("proxyHost");
		save();
		return super.configure(req, json);
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getProxyPort() {
		return proxyPort;
	}

	public void setProxyPort(String proxyPort) {
		this.proxyPort = proxyPort;
	}

	public String getProxyHost() {
		return proxyHost;
	}

	public void setProxyHost(String proxyHost) {
		this.proxyHost = proxyHost;
	}
	
	
	
    
   
}
