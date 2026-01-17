public class CustomSendMailUtil {     
    
    public static Messaging.SingleEmailMessage SetCustomSingleEmail(List<String> toAddress,String subject,String textbody, String htmlbody, String orgEmail){
                    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(toAddress.size() > 0) mail.setToAddresses(toAddress);
        if(orgEmail <> null) mail.setOrgWideEmailAddressId(orgEmail); 
        if(subject <> null) mail.setSubject(subject);
        if(textbody <> null) mail.setPlainTextBody(textbody);
        if(htmlbody <> null) mail.setHTMLBody(htmlbody);
        return mail;
    }
}