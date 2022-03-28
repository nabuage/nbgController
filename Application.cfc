component {

	THIS.name = "ApplicationName_" & hash(getCurrentTemplatePath());
	THIS.applicationTimeout = createTimeSpan(1,0,0,0);
	THIS.sessionTimeout = createTimeSpan(1,0,0,0);
	THIS.sessionManagement = true;
	THIS.setClientCookies = false;
	
	cfsetting(
        requestTimeout = 20, 
        enableCFoutputOnly = false, 
        showDebugOutput = false
    );

	public boolean function onApplicationStart() {
		return true;
	}

	public void function onApplicationEnd(struct applicationScope={}) {
		return;
	}

	public void function onSessionStart() {
		return;
	}

	public void function onSessionEnd(required struct sessionScope, struct applicationScope={}) {
		return;
	}

	public boolean function onRequestStart(required string targetPage) {
        (new controller.org.nabuage.Controller()).run();
		return true;
	}

	public void function onRequest(required string targetPage) {
		include arguments.targetPage;
		return;
	}

	public void function onCFCRequest(string cfcname, string method, struct args) {
		return;
	}

	public void function onRequestEnd() {
		return;
	}

	public void function onAbort(required string targetPage) {
		return;
	}

	public void function onError(required any exception, required string eventName) {
		return;
	}

	public boolean function onMissingTemplate(required string targetPage) {
		return true;
	}
}