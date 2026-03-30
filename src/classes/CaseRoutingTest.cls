@IsTest
private class CaseRoutingTest {
  private static final String QUEUE_POLICY_SERVICES = 'Policy_Services';
  private static final String QUEUE_BILLING_SUPPORT = 'Billing_Support';
  private static final String QUEUE_CLAIMS_INTAKE = 'Claims_Intake';

  private static Group getQueue(String developerName) {
    List<Group> queues = [
      SELECT Id, Name, DeveloperName
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = :developerName
      LIMIT 1
    ];
    System.assert(!queues.isEmpty(), 'Queue not found in org: ' + developerName);
    return queues[0];
  }

  private static Case insertCase(String subject, String description) {
    Case c = new Case(Subject = subject, Description = description, Status = 'New', Origin = 'Web');
    insert c;
    return [SELECT Id, OwnerId, Subject, Status FROM Case WHERE Id = :c.Id];
  }

  @IsTest
  static void testRoutesToClaimsIntake() {
    Group q = getQueue(QUEUE_CLAIMS_INTAKE);

    Test.startTest();
    Case c = insertCase('First notice of loss', 'I was in an accident and need to file a claim.');
    Test.stopTest();

    System.assertEquals(q.Id, c.OwnerId, 'Case should be routed to the Claims Intake queue');
  }

  @IsTest
  static void testRoutesToBillingSupport() {
    Group q = getQueue(QUEUE_BILLING_SUPPORT);

    Test.startTest();
    Case c = insertCase('Payment failed', 'My premium payment did not go through and I have a billing question.');
    Test.stopTest();

    System.assertEquals(q.Id, c.OwnerId, 'Case should be routed to the Billing Support queue');
  }

  @IsTest
  static void testRoutesToPolicyServices() {
    Group q = getQueue(QUEUE_POLICY_SERVICES);

    Test.startTest();
    Case c = insertCase('Policy endorsement request', 'I need to make a change to my policy coverage.');
    Test.stopTest();

    System.assertEquals(q.Id, c.OwnerId, 'Case should be routed to the Policy Services queue');
  }

  /**
   * TDD anchor — intentionally RED until the routing Flow is deployed.
   * A Case with no recognisable keyword should default to Policy Services.
   */
  @IsTest
  static void testDefaultsToPolicyServices() {
    Group q = getQueue(QUEUE_POLICY_SERVICES);

    Test.startTest();
    Case c = insertCase('General enquiry', 'I have a question about my account.');
    Test.stopTest();

    System.assertEquals(q.Id, c.OwnerId, 'A Case with no routing keyword should default to the Policy Services queue');
  }

  /**
   * Edge case: Subject/Description contains keywords from multiple queues
   * ('payment' + 'claim'). Ambiguous cases should fall through to the default
   * Policy Services queue rather than making an arbitrary routing decision.
   */
  @IsTest
  static void testAmbiguousKeywordsDefaultToPolicyServices() {
    Group q = getQueue(QUEUE_POLICY_SERVICES);

    Test.startTest();
    Case c = insertCase(
      'Question about my claim payment',
      'I received a settlement on my claim but have a question about the payment amount.'
    );
    Test.stopTest();

    System.assertEquals(
      q.Id,
      c.OwnerId,
      'A Case with mixed keywords (claim + payment) should default to the Policy Services queue'
    );
  }
}
