trigger TC_CampaignMember on CampaignMember (before insert, before update, before delete, after insert, after update, after delete) {
    new TC_CampaignMemberHelper().execute();
}