package com.intuit.ctg.devops.jenkinsplugins;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class ArtifactLogParser {

	private static final String IGNORED_RESOURCE_METADATA ="^.*maven-metadata.xml$";
	private static final String IGNORED_RESOURCE_POM ="^.*.pom$";
	private static final String IGNORED_RESOURCE_SOURCES ="^.*sources.jar$";
	private static final String IGNORED_RESOURCE_JAVADOC ="^.*javadoc.jar$";

	public static List<String> parseLogFile(File logFile) throws IOException{
		BufferedReader in = new BufferedReader(new FileReader(logFile));
		Pattern pattern = Pattern.compile("^.*?Uploading: (.*?)$");
		Pattern ignoredPatternMetadata = Pattern.compile(IGNORED_RESOURCE_METADATA);
		Pattern ignoredPatternPom = Pattern.compile(IGNORED_RESOURCE_POM);
		Pattern ignoredPatternSources = Pattern.compile(IGNORED_RESOURCE_SOURCES);
		Pattern ignoredPatternJavadoc = Pattern.compile(IGNORED_RESOURCE_JAVADOC);
		String line;
		List<String> matches = new ArrayList<String>();
		while ((line = in.readLine()) != null) {
			Matcher matcher = pattern.matcher(line);
			if (matcher.matches()) {
				String candidate = matcher.group(1);
				Matcher ignoredMatcher1 = ignoredPatternMetadata.matcher(candidate);
				Matcher ignoredMatcher2 = ignoredPatternPom.matcher(candidate);
				Matcher ignoredMatcher3 = ignoredPatternSources.matcher(candidate);
				Matcher ignoredMatcher4 = ignoredPatternJavadoc.matcher(candidate);
				if (!ignoredMatcher1.matches() && !ignoredMatcher2.matches()
						&& !ignoredMatcher3.matches() && !ignoredMatcher4.matches()) {
					matches.add(candidate);
				}
			}
		}
		if(in != null){
			in.close();
		}
		return matches;
	}

	public static List<Artifact> parseArtifacts(File logFile) throws IOException {
		List<String> locationUrls = parseLogFile(logFile);
		
		List<Artifact> artifacts = new ArrayList<Artifact>();
		Artifact art = null;
		String artIDVersionStr = null;
		String artifactId = "";

		String repositoryStr = "/repositories/";
		String DELIMITER = "/";
		String DOT_DELIMITER = ".";
		String versionRegex = "/\\d+\\.";
		Pattern versionpattern = Pattern.compile(versionRegex);
		Pattern artifactVersionPattern = Pattern.compile("(\\d+\\.[a-zA-Z])|(\\d+-[a-zA-Z])");
		int indexofDotORDashInArtVersion = 0;
		String classifierTypeStr = "";
		for(String url : locationUrls){

			art = new Artifact(url);
			//parse location url to get groupid, artifactid, classifier and type 
			url = url.substring(url.indexOf(repositoryStr)+repositoryStr.length());
			url = url.substring(url.indexOf(DELIMITER)+1); // get rid of respository string
			Matcher matcher = versionpattern.matcher(url);
			if (matcher.find()) {
				artIDVersionStr = url.substring(matcher.end());
				artIDVersionStr = artIDVersionStr.substring(artIDVersionStr.indexOf(DELIMITER));
				url = (url.substring(0, matcher.start()));
				art.setGroupId(url.substring(0, url.lastIndexOf(DELIMITER)).replaceAll(DELIMITER, "."));
				artifactId = url.substring(url.lastIndexOf(DELIMITER)+1);
				art.setArtifactId(artifactId);
				artIDVersionStr = artIDVersionStr.substring(artifactId.length()+2);
				Matcher artifactVersionMatcher = artifactVersionPattern.matcher(artIDVersionStr);
				if (artifactVersionMatcher.find()) {
					indexofDotORDashInArtVersion = (artifactVersionMatcher.group().indexOf(DOT_DELIMITER) == -1) ?  
							artifactVersionMatcher.group().indexOf("-") : artifactVersionMatcher.group().indexOf(DOT_DELIMITER);
					art.setVersion(artIDVersionStr.substring(0,artifactVersionMatcher.start()+indexofDotORDashInArtVersion));
					classifierTypeStr = artIDVersionStr.substring(artifactVersionMatcher.start()+indexofDotORDashInArtVersion, artIDVersionStr.length());
					art.setType(classifierTypeStr.substring(classifierTypeStr.indexOf(DOT_DELIMITER)+1));
					if(classifierTypeStr.startsWith("-")){
						art.setClassifier(classifierTypeStr.substring(1, classifierTypeStr.indexOf(DOT_DELIMITER)));
					}
				}
			}
			artifacts.add(art);

		}

		return artifacts;
	}
}
