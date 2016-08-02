package com.intuit.ctg.devops.jenkinsplugins;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import hudson.EnvVars;
import hudson.Launcher;
import hudson.model.BuildListener;
import hudson.model.Result;
import hudson.model.AbstractBuild;
import hudson.model.HealthReport;
import hudson.model.User;
import hudson.plugins.clover.Ratio;
import hudson.plugins.clover.CloverBuildAction;
import hudson.plugins.cobertura.CoberturaBuildAction;
import hudson.plugins.cobertura.targets.CoverageMetric;
import hudson.scm.ChangeLogSet;
import hudson.scm.ChangeLogSet.Entry;
import hudson.tasks.test.AbstractTestResultAction;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

import com.google.common.collect.Sets;

public class BuildMetricsPublisherTest {
	
	
	private static final String URL = "http://url";
	private static final String HEADERS = "s:s";
	private static final String STR = "test";
	private static final String LOGFILE = "src/test/resources/buildlog";
	private static final String JOB_NAME = "JOB_NAME";
	private static final String JENKINS_URL = "JENKINS_URL";
	private static final String BUILD_URL = "BUILD_URL";
	
	private BuildMetricsPublisher publisher;
	private AbstractBuild<?, ?> mockBuild;
	HealthReport mockReport;
	Launcher mockLauncher;
	BuildListener mockListener;
	
	private static class MockEntry extends Entry {

        private final String msg;

        public MockEntry(String msg) {
            this.msg = msg;
        }

        @Override
        public Collection<String> getAffectedPaths() {
            return null;
        }

        @Override
        public User getAuthor() {
            return null;
        }

        @Override
        public String getMsgAnnotated() {
            return this.msg;
        }

		@Override
		public String getMsg() {
			return this.msg;
		}
    }

	

	@SuppressWarnings({ "rawtypes", "unchecked" })
	@Before
	public void setUp() throws Exception{
		publisher = new BuildMetricsPublisher(URL, HEADERS);
		
		mockBuild = mock(AbstractBuild.class);
		mockLauncher = mock(Launcher.class);
		mockListener = mock(BuildListener.class);
			PrintStream a = new PrintStream(System.out);
		when(mockListener.getLogger()).thenReturn(a);
		when(mockBuild.getResult()).thenReturn(Result.SUCCESS);
		
		EnvVars envVars = createEnvVars();
		when(mockBuild.getEnvironment(mockListener)).thenReturn(envVars);
		
		
		File file = new File(LOGFILE);
		when(mockBuild.getLogFile()).thenReturn(file);
		
		ChangeLogSet changeLog = mock(ChangeLogSet.class);
		when(mockBuild.getChangeSet()).thenReturn(changeLog);
		
		final MockEntry entry1 = new MockEntry("FOOBAR-1: The first build");
                final MockEntry entry2 = new MockEntry("FOODBAR-2 FOODBAR-3: FOOBAR-4 First build");
		final Set<? extends Entry> entries = Sets.newHashSet(entry1, entry2);
		when(changeLog.iterator()).thenAnswer(new Answer<Object>() {

            public Object answer(final InvocationOnMock invocation) throws Throwable {
                return entries.iterator();
            }
        });		
		when(mockBuild.getUrl()).thenReturn(URL);
		
		AbstractTestResultAction mockTestAction = mock(AbstractTestResultAction.class);
		when(mockBuild.getAction(AbstractTestResultAction.class)).thenReturn(mockTestAction);
		
		when(mockTestAction.getUrlName()).thenReturn(STR);
		when(mockTestAction.getTotalCount()).thenReturn(1);
		when(mockTestAction.getFailCount()).thenReturn(0);
		hudson.tasks.junit.TestResult mockResult = new hudson.tasks.junit.TestResult();
		when(mockTestAction.getResult()).thenReturn(mockResult);
		
		mockReport = mock(HealthReport.class);
		when(mockReport.getDescription()).thenReturn(STR);
		when(mockReport.getScore()).thenReturn(50);
	}
	
	@After
	public void tearDown(){
		publisher = null;
	}
	
	@Test
	public void test_perform_Clover() throws IOException, InterruptedException {
		
		
		CloverBuildAction cloverAction = mock(CloverBuildAction.class);
		when(mockBuild.getAction(CloverBuildAction.class)).thenReturn(cloverAction);
		when(cloverAction.getUrlName()).thenReturn(STR);
		
		when(cloverAction.getBuildHealth()).thenReturn(mockReport);
		Ratio mockRatio = Ratio.create(6, 1);
		when(cloverAction.getMethodCoverage()).thenReturn(mockRatio);
		when(cloverAction.getConditionalCoverage()).thenReturn(mockRatio);
		when(cloverAction.getStatementCoverage()).thenReturn(mockRatio);
		
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);
		
	}
	
	@Test
	public void test_perform_Cobertura() throws IOException, InterruptedException {
		
		
		CoberturaBuildAction action = mock(CoberturaBuildAction.class);
		when(mockBuild.getAction(CoberturaBuildAction.class)).thenReturn(action);
		when(action.getUrlName()).thenReturn(STR);
		
		when(action.getBuildHealth()).thenReturn(mockReport);
		hudson.plugins.cobertura.Ratio mockRatio = hudson.plugins.cobertura.Ratio.create(6, 1);
		Map<CoverageMetric, hudson.plugins.cobertura.Ratio> resultMap = new HashMap<CoverageMetric, hudson.plugins.cobertura.Ratio>();
		resultMap.put(CoverageMetric.CLASSES, mockRatio);
		
		when(action.getResults()).thenReturn(resultMap);
		
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);
	}
	
	@Test
	public void test_perform() throws IOException, InterruptedException {
		when(mockBuild.getChangeSet()).thenReturn(null);
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);
	}
	
	@Test
	public void test_InvalidURL() throws IOException, InterruptedException {
		publisher = new BuildMetricsPublisher("ftp://", null);
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);
	}
	
	@Test
	public void test_NullURL() throws IOException, InterruptedException {
		publisher = new BuildMetricsPublisher(null, null);
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);
	}
	
	@Test
	public void test_InvalidHeaders() throws IOException, InterruptedException {
		publisher = new BuildMetricsPublisher(URL, STR);
		boolean result = publisher.perform(mockBuild, mockLauncher, mockListener);
		assertFalse(result);

	}
	
	@Test
	public void test_needsToRunAfterFinalized() {
		publisher = new BuildMetricsPublisher(URL, HEADERS);
		// Call Method to Test
		boolean result = publisher.needsToRunAfterFinalized();

		// Validate Results
		assertTrue(result);
	}
	
	
	private EnvVars createEnvVars() {
		Map<String, String> envVars = new HashMap<String, String>();

		envVars.put(JOB_NAME, STR);
		envVars.put(JENKINS_URL, URL);
		envVars.put(BUILD_URL, URL);

		return new EnvVars(envVars);
	}
}
