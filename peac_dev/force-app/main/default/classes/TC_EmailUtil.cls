public with sharing class TC_EmailUtil {
    /**
     * Sends an email notification
     *
     * @param toAddresses Optional      - A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum number of email addresses allowed is 100.
     * @param ccAddresses Optional      - A list of carbon copy (CC) addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum allowed is 25.
     * @param whatId Optional           - If you specify a contact for the targetObjectId field, you can specify an optional whatId as well. This helps to further ensure that merge fields in the template contain the correct data.
     * @param whoId Required            - If using a template, optional otherwise. The ID of the contact, lead, or user to which the email will be sent. The ID you specify sets the context and ensures that merge fields in the template contain the correct data.
     * @param subject Optional          - The email subject line. If you are using an email template, the subject line of the template overrides this value.
     * @param body Optional             - The text version of the email, specified by the sender. You must specify a value for setTemplateId, setHtmlBody, or setPlainTextBody. Or, you can define both setHtmlBody and setPlainTextBody.
     * @param senderDisplayNm Optional  - The name that appears on the From line of the email. This cannot be set if the object associated with a setOrgWideEmailAddressId for a SingleEmailMessage has defined its DisplayName field.
     * @param templateId Optional       - Required if using a template, optional otherwise. The ID of the template used to create the email.
     *
     * @return                          The list of resulting emails after sending
     */
    public static List<Messaging.SendEmailResult> sendEmailNotification(
            List<String> toAddresses,
            List<String> ccAddresses,
            String whatId,
            String whoId,
            String subject,
            String body,
            String orgWideEmailId,
            String senderDisplayNm,
            String templateId
    ) {
        Messaging.SingleEmailMessage mail = setupSingleEmail(toAddresses, ccAddresses, whatId, whoId, subject, body, orgWideEmailId, senderDisplayNm, templateId);

        return Messaging.sendEmail(new List<Messaging.Email>{
                mail
        });
    }

    /**
     * Creates an email notification
     *
     * @param toAddresses Optional      - A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum number of email addresses allowed is 100.
     * @param ccAddresses Optional      - A list of carbon copy (CC) addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum allowed is 25.
     * @param whatId Optional           - If you specify a contact for the targetObjectId field, you can specify an optional whatId as well. This helps to further ensure that merge fields in the template contain the correct data.
     * @param whoId Required            - If using a template, optional otherwise. The ID of the contact, lead, or user to which the email will be sent. The ID you specify sets the context and ensures that merge fields in the template contain the correct data.
     * @param subject Optional          - The email subject line. If you are using an email template, the subject line of the template overrides this value.
     * @param body Optional             - The text version of the email, specified by the sender. You must specify a value for setTemplateId, setHtmlBody, or setPlainTextBody. Or, you can define both setHtmlBody and setPlainTextBody.
     * @param senderDisplayNm Optional  - The name that appears on the From line of the email. This cannot be set if the object associated with a setOrgWideEmailAddressId for a SingleEmailMessage has defined its DisplayName field.
     * @param templateId Optional       - Required if using a template, optional otherwise. The ID of the template used to create the email.
     *
     * @return                          The constructed email notification
     */
    public static Messaging.SingleEmailMessage setupSingleEmail(
            List<String> toAddresses,
            List<String> ccAddresses,
            String whatId,
            String whoId,
            String subject,
            String body,
            String orgWideEmailId,
            String senderDisplayNm,
            String templateId
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (toAddresses != null) {
            mail.setToAddresses(toAddresses);
        }
        if (ccAddresses != null) {
            mail.setCcAddresses(ccAddresses);
        }
        mail.setSenderDisplayName(senderDisplayNm);
        mail.setOrgWideEmailAddressId(orgWideEmailId);
        mail.setSubject(subject);
        mail.setUseSignature(false);
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity(false);
        // mail.setEmailPriority(priority);
        // mail.setTemplateId(templateId);
        if (whatId!=null) {
            mail.whatId = whatId;
        }
        if (whoId!=null) {
            mail.targetObjectId = whoId;
        }
        return mail;
    }
}