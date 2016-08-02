package com.intuit.ctg.devops.jenkinsplugins;

import java.util.regex.Pattern;


public class Artifact {
	private static final String SNAPSHOT_PATTERN = ".*-SNAPSHOT.*";
	private static final Pattern p = Pattern.compile(SNAPSHOT_PATTERN);

	private String groupId ;
	private String artifactId ;
	private String classifier;
	private String type ;
	private String version ;
	private String locationUrl ;
	private boolean release ;

	public Artifact(String locationUrl){
		this.locationUrl = locationUrl;
		release = !(p.matcher(locationUrl).matches());
        
	}

	public String getGroupId() {
		return groupId;
	}
	public void setGroupId(String groupId) {
		this.groupId = groupId;
	}
	public String getArtifactId() {
		return artifactId;
	}
	public void setArtifactId(String artifactId) {
		this.artifactId = artifactId;
	}
	public String getClassifier() {
		return classifier;
	}
	public void setClassifier(String classifier) {
		this.classifier = classifier;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getVersion() {
		return version;
	}
	public void setVersion(String version) {
		this.version = version;
	}
	public String getLocationUrl() {
		return locationUrl;
	}
	public boolean isRelease() {
		return release;
	}
	public void setRelease(boolean release) {
		this.release = release;
	}
	
	

}
