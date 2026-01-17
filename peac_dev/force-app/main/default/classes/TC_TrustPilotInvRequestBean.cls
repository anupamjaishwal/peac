public class TC_TrustPilotInvRequestBean {
	public String referenceId;
    public String name;
    public String locale;
    public String email;
    public Id oppId;
    public String redirectUri;
    
    public TC_TrustPilotInvRequestBean (String referenceId, String name, String email, Id oppId) {
        this.referenceId = referenceId;
        this.name = name;
        this.locale = 'en-US';
        this.email = email;
        this.redirectUri = 'https://marlincapitalsolutions.com/';
        this.oppId = oppId;
    }
}