package com.intuit.ctg.devops.jenkinsplugins;

import java.io.IOException;
import java.io.PrintStream;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URL;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import hudson.Launcher;
import hudson.model.BuildListener;
import hudson.model.AbstractBuild;
import hudson.plugins.clover.CloverBuildAction;
import hudson.plugins.cobertura.Ratio;
import hudson.plugins.cobertura.CoberturaBuildAction;
import hudson.plugins.cobertura.targets.CoverageMetric;
import hudson.scm.ChangeLogSet;
import hudson.scm.ChangeLogSet.Entry;
import hudson.tasks.BuildStepMonitor;
import hudson.tasks.Notifier;
import hudson.tasks.test.AbstractTestResultAction;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;
import org.kohsuke.stapler.DataBoundConstructor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.squareup.okhttp.Headers;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.Request.Builder;
import com.squareup.okhttp.RequestBody;
import com.squareup.okhttp.Response;

import java.util.regex.Pattern;
import java.util.regex.Matcher;

import org.apache.commons.codec.binary.Base64;




public class BuildMetricsPublisher  extends Notifier {
	private static final Logger JENKINS_LOG = Logger.getLogger(BuildMetricsPublisher.class.getName());
	private static final String AUTH_HEADER = "Authorization";
    private static final String CONTENT_TYPE_HEADER = "Content-Type";
    private static final String BUILD_URL = "BUILD_URL";

	private String url;
	private String headers;

	private static final MediaType JSON
	= MediaType.parse("application/json; charset=utf-8");
	
	private OkHttpClient httpClient = new OkHttpClient();;

	@DataBoundConstructor
	public BuildMetricsPublisher(String url, String headers){
		this.url = url;
		this.headers = headers;
	}

	ObjectMapper mapper = new ObjectMapper();
        
         /**
         * Regexp pattern that identifies JIRA issue token.
         * First char must be a letter, then at least one letter, digit or underscore.
         * See issue JENKINS-729, JENKINS-4092
         */
        public static final Pattern DEFAULT_ISSUE_PATTERN = Pattern.compile("([a-zA-Z][a-zA-Z0-9_]+-[1-9][0-9]*)([^.]|\\.[^0-9]|\\.$|$)");
        public static final String STRING_DELIMINATOR = ",";

	@SuppressWarnings({ "rawtypes" })
	@Override
	public boolean perform(AbstractBuild<?,?> build, Launcher launcher, BuildListener listener) throws IOException, InterruptedException {
		PrintStream jobLog = listener.getLogger();
		boolean status = false;
		try{

			validateUrl(url);
			validateHeaders(headers);

			Map<String, Object> uploadMap = new HashMap<String, Object>();

			Map<String, Object> proprtiesMap = new HashMap<String, Object>();
			//artifacts

			List<Artifact> artifacts = ArtifactLogParser.parseArtifacts(build.getLogFile());

			uploadMap.put("artifacts", artifacts);

			//buildStatus
			proprtiesMap.put("status", build.getResult().toString());

			StringBuilder sb = new StringBuilder();
                        StringBuilder sb_jira = new StringBuilder();
                        String jiraIDs = new String();
			//changelist
			ChangeLogSet<? extends Entry> changeSet = build.getChangeSet();

			if(changeSet != null){
                                
				Iterator<? extends Entry> iterator = changeSet.iterator();
				while(iterator.hasNext()){
					Entry r = iterator.next();
                                        Matcher m = DEFAULT_ISSUE_PATTERN.matcher(r.getMsg());
                                        while (m.find()){
                                           if (m.groupCount() >= 1){
                                               //TO DO: Add a passing test
                                               // tested via system.out
                                               sb_jira.append(m.group(1)).append(STRING_DELIMINATOR);
                                           }
                                           
                                        }
                                        if (sb_jira.toString().endsWith(STRING_DELIMINATOR)){
                                           jiraIDs = sb_jira.toString().substring(0, sb_jira.length() - 1);
                                        } else{
                                           jiraIDs = sb_jira.toString();
                                        }
					sb.append(r.getMsgAnnotated());
				}
			}

			if(sb.length() > 0){
				proprtiesMap.put("changelist", sb.toString());
			}
                        if (sb_jira.length() > 0){
                            proprtiesMap.put("jiraIDs", jiraIDs);
                        }
			Map<String, String> envVars = build.getEnvironment(listener);

			String buildUrl =   envVars.get(BUILD_URL);
			proprtiesMap.put("buildUrl", buildUrl);
			//covers testng and junit
			AbstractTestResultAction testAction =  build.getAction(AbstractTestResultAction.class);
			sb = new StringBuilder();
			if(testAction != null){
				String testResultURL = testAction.getUrlName();
				proprtiesMap.put("testResultUrl", buildUrl+testResultURL);
				proprtiesMap.put("totalTests", testAction.getTotalCount());
				proprtiesMap.put("failedTests", testAction.getFailCount());
				hudson.tasks.junit.TestResult testResult = (hudson.tasks.junit.TestResult)testAction.getResult();
				proprtiesMap.put("testDuration", testResult.getDuration());
			}

			CloverBuildAction cloverAction = build.getAction(CloverBuildAction.class);
			if(cloverAction != null){
				jobLog.println("Colver Report ::::::::::");
				proprtiesMap.put("coverageUrl", buildUrl+cloverAction.getUrlName());
				proprtiesMap.put("coverageDesc", cloverAction.getBuildHealth().getDescription());
				proprtiesMap.put("coverageScore", cloverAction.getBuildHealth().getScore());
				proprtiesMap.put("methods", cloverAction.getMethodCoverage().getPercentage());
				proprtiesMap.put("conditionals", cloverAction.getConditionalCoverage().getPercentage());
				proprtiesMap.put("statements", cloverAction.getStatementCoverage().getPercentage());
			}else{
				CoberturaBuildAction coverageAction = build.getAction(CoberturaBuildAction.class);
				if(coverageAction != null){
					jobLog.println("Cobertura Report ::::::::::");
					proprtiesMap.put("coverageUrl", buildUrl+coverageAction.getUrlName());
					proprtiesMap.put("coverageDesc", coverageAction.getBuildHealth().getDescription());
					proprtiesMap.put("coverageScore", coverageAction.getBuildHealth().getScore());
					Map<CoverageMetric, Ratio> result = coverageAction.getResults();
					for(Map.Entry<CoverageMetric, Ratio> entry : result.entrySet()){
						proprtiesMap.put(entry.getKey().getName().toLowerCase(), entry.getValue().getPercentage());
					}
				}
			}

			uploadMap.put("properties", proprtiesMap);

			String jsonInString = mapper.writeValueAsString(uploadMap);
			jobLog.println("final output: "+ jsonInString);

			if(artifacts != null && !artifacts.isEmpty()){
				jobLog.println("Posting to :"+url);
				int responseCode = post(url, jsonInString, headers, build, buildUrl, jobLog);
				jobLog.println("POST response code: "+responseCode);
			}	
			status = true;
			
		}
		catch (Exception e) {
			JENKINS_LOG.log(Level.SEVERE, "Failed to POST build metrics.  Exception: ", e);
			e.printStackTrace(jobLog);
		}
		return status;
	}	

	private int post(String url, String json, String headers, AbstractBuild<?,?> build, String buildUrl, PrintStream jobLog) throws IOException {

		String username = getDescriptor().getUsername();
		String password = getDescriptor().getPassword();

		if(StringUtils.isBlank(username) || StringUtils.isBlank(password)){
			throw new IllegalArgumentException("Global credentials not configured; cannot POST to :"+url);
		}

		RequestBody body = RequestBody.create(JSON, json);
		Builder builder = new Request.Builder()
		.url(url)
		.post(body)
		.header("Build-URL", buildUrl)
		.header("Build-Timestamp", String.valueOf(build.getTimeInMillis()));

		String value = String.format("Basic %s", basicAuth(username, password));
		builder.header(AUTH_HEADER, value);
		builder.header(CONTENT_TYPE_HEADER, "application/json");

		if (headers != null && headers.length() > 0) {
			String[] lines = headers.split("\r?\n");
			for (String line : lines) {
				int index = line.indexOf(':');
				builder.header(line.substring(0, index).trim(), line.substring(index + 1).trim());
			}
		}
		Request request = builder.build();
		System.setProperty("jsse.enableSNIExtension", "false");		
		
		String proxyPort = getDescriptor().getProxyPort();
		String proxyHost = getDescriptor().getProxyHost();
		
		jobLog.println("proxyPort:"+proxyPort);
		jobLog.println("proxyHost:"+proxyHost);
		if(StringUtils.isNotBlank(proxyPort) && StringUtils.isNotBlank(proxyHost)){
		
			httpClient.setProxy(new Proxy(Proxy.Type.HTTP, new InetSocketAddress(proxyHost, Integer.parseInt(proxyPort))));
			jobLog.println("inside proxy");
		}
		httpClient.setConnectTimeout(300, TimeUnit.SECONDS);
		Response response = httpClient.newCall(request).execute();

		return response.code();
	}

	private static String basicAuth(String username, String password)
	{
		return Base64.encodeBase64String(String.format("%s:%s", username, password).getBytes());
	}

	@Override
	public BuildStepMonitor getRequiredMonitorService() {
		return BuildStepMonitor.NONE;
	}

	@Override
	public DescriptorImpl getDescriptor() {
		return (DescriptorImpl) super.getDescriptor();
	}

	@Override
	public boolean needsToRunAfterFinalized() {
		return true;
	}

	public String getUrl() {
		return url;
	}

	public String getHeaders() {
		return headers;
	}

	private void validateUrl(String value) throws IllegalArgumentException{
		if (StringUtils.isBlank(value)) {
			throw new IllegalArgumentException("URL must not be empty");
		}

		if (!value.startsWith("http://") && !value.startsWith("https://")) {
			throw new IllegalArgumentException("URL must start with http:// or https://");
		}

		try {
			new URL(value).toURI();
		} catch (Exception e) {
			throw new IllegalArgumentException(e.getMessage());
		}

	}

	private void validateHeaders(String value) throws  IllegalArgumentException{
		if (StringUtils.isNotBlank(value)) {
			Headers.Builder headers = new Headers.Builder();
			String[] lines = value.split("\r?\n");

			for (String line : lines) {
				int index = line.indexOf(':');
				if (index == -1) {
					throw new IllegalArgumentException("Unexpected header: " + line);
				}

				try {
					headers.add(line.substring(0, index).trim(), line.substring(index + 1).trim());
				} catch (Exception e) {
					throw new IllegalArgumentException(e.getMessage());
				}
			}
		}

	}

}


